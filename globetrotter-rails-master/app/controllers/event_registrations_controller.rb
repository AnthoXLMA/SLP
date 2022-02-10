# frozen_string_literal: true

class EventRegistrationsController < ApplicationController
  before_action :set_event_registration, only: %i[show edit update destroy]
  before_action :set_full_event_registration, only: %i[after_event tip pay after_pay]
  before_action :set_common_payment_variables, only: %i[tip pay]
  before_action :authenticate_user!

  # GET /event_registrations or /event_registrations.json
  def index
    @event_registrations =
      EventRegistration.includes(event: {
                                   tour: {
                                     guide: [:user, { image_attachment: :blob }],
                                     thumbnail_attachment: :blob
                                   }
                                 })
                       .includes(:comment)
                       .where(user: current_user)
                       .order('events.date asc')
                       .all
    now = Time.now.round
    @previous_registrations = @event_registrations.select { |er| er.event.date < now }
    @upcoming_registrations = @event_registrations.select { |er| er.event.date >= now }
    @suggested_tours = Tour.suggested(current_user)
                           .includes(guide: [:user, { image_attachment: :blob }])
                           .includes(thumbnail_attachment: :blob)
                           .includes(:next_event)
                           .joins(:next_event)
                           .where.not(id: @event_registrations.map(&:tour).map(&:id))
  end

  # POST /event_registrations or /event_registrations.json
  def create
    @event_registration = EventRegistration.new(event_registration_params.merge(user_id: current_user.id))

    e = Event.for(current_user).where(id: @event_registration.event_id).first
    if e
      e.with_lock do
        if e.cancelled?
          @event_registration.errors.add(:event, I18n.t('registration.event_is_cancelled'))
        else
          @event_registration.save
          @event_registration.allow_strict_loading do
            ApplicationMailer
              .with({ user_id: @event_registration.user_id, event_id: @event_registration.event_id })
              .event_registration
              .deliver_later
          end
        end
      end
    else
      @event_registration.errors.add(:event, t('registration.event_must_exist'))
    end

    @event_registration.allow_strict_loading do
      if @event_registration.errors.empty?
        redirect_to tour_path(@event_registration.event.tour_id),
                    notice: t('registration.successfull')
      else
        tour_id = @event_registration&.event&.tour_id
        rpath = tour_id ? tour_path(@event_registration.event.tour_id) : welcome_path
        redirect_to rpath,
                    alert: t('registration.unsuccessfull', reason: @event_registration.errors.full_messages.to_sentence)
      end
    end
  end

  # DELETE /event_registrations/1 or /event_registrations/1.json
  def destroy
    raise UnauthorizedException, t('registration.only_registered_user_can_unregister') if @event_registration.user_id != current_user.id

    if @event_registration.event.date < Time.now
      raise UnauthorizedException,
            t('registration.only_registrations_to_future_event_can_be_cancelled')
    end

    # send email now because the database object is about to be deleted
    @event_registration.send_cancellation(:deliver_now, application_mailer)

    # allow dependent comments to be deleted (normally there shouldn't be any comment)
    @event_registration.allow_strict_loading do
      @event_registration.destroy
      respond_to do |format|
        format.html do
          redirect_to tour_path(@event_registration.event.tour_id),
                      notice: t('registration.successfully_cancelled')
        end
        format.json { head :no_content }
      end
    end
  end

  def after_event
    if @event_registration.user_id != current_user.id
      raise UnauthorizedException,
            t('registration.only_registered_user_can_view_this_page')
    end
    @event_registration.end_visit_date = Time.now
    @event_registration.save!
  end

  def tip
    if @event_registration.user_id != current_user.id
      raise UnauthorizedException,
            t('registration.only_registered_user_can_view_this_page')
    end

    @payment = Payment.new
  end

  def pay
    if @event_registration.user_id != current_user.id
      raise UnauthorizedException,
        t('registration.only_registered_user_can_view_this_page')
    end

    @payment = Payment.new(payment_params)
    respond_to do |format|
      if @payment.valid?
        guide_wallet = MangoPayWallet.getOrCreate(@event_registration.event.tour.guide.user, @payment.currency)
        user_wallet = MangoPayWallet.getOrCreate(current_user, @payment.currency)
        web_pay_in = MangoPayWallet.requestPaymentUrl(current_user, guide_wallet, user_wallet, @payment,
                                                      after_pay_event_registration_url(@event_registration))
        format.html { redirect_to web_pay_in['RedirectURL'] }
        format.json { render json: web_pay_in }
      else
        format.html { render :tip, status: :unprocessable_entity }
        format.json { render json: @payment.errors, status: :unprocessable_entity }
      end
    end
  end

  def after_pay
    # http://localhost:3000/event_registrations/8/after_pay?transactionId=119794038
    # http://localhost:3000/event_registrations/8/after_pay?transactionId=119796659
    if @event_registration.user_id != current_user.id
      raise UnauthorizedException,
        t('registration.only_registered_user_can_view_this_page')
    end

    transaction = MangoPayWallet.getTransaction(current_user, params['transactionId'])
    if !transaction.nil? && transaction['Status'] == 'SUCCEEDED' && transaction['CreditedUserId'] == current_user.mangopay_user_id
      # Initial transaction was to load e-wallet - we transfer the amount the user was willing to pay to the guide (taking fees)
      amount = params['tip'].to_f
      currency = transaction['DebitedFunds']['Currency']
      Rails.logger.debug 'Processing ' + amount.to_s + ' ' + currency + 'wallet to wallet transfer for ' + params['transactionId']
      guide_wallet = MangoPayWallet.getOrCreate(@event_registration.event.tour.guide.user, currency)
      user_wallet = MangoPayWallet.getOrCreate(current_user, currency)
      @transaction = MangoPayWallet.walletTransfer(guide_wallet, user_wallet, amount)
    else
      @transaction = transaction
    end
    Rails.logger.debug @transaction
  end

  private

  def payment_params
    params.require(:payment).permit(:amount, :currency, :payment_type, :ewallet_amount)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_event_registration
    @event_registration = EventRegistration.includes(:event).find(params[:id])
  end

  def set_full_event_registration
    @event_registration = EventRegistration.includes(event: { tour: { guide: :user } }).find(params[:id])
  end

  def set_common_payment_variables
    @currencies = [['EUR'], ['USD'], ['GBP']]
    @payment_types = [[t('events.mangopay_cards'), 'mangopay_cards'],
                      [t('events.mangopay_ewallet'), 'mangopay_ewallet']]
  end

  # Only allow a list of trusted parameters through.
  def event_registration_params
    params.require(:event_registration).permit(:event_id)
  end

  def application_mailer
    ApplicationMailer
  end
end
