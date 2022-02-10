// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

require("../../../semantic/dist/semantic.css")
require("../../../semantic/dist/semantic.js")
require("stylesheets/application.scss")
require("stylesheets/tours.scss")
require("stylesheets/welcome.scss")

const images = require.context("../../assets/images", true)
const imagePath = name => images(name, true)

const getLocale = function() {
  const locale = $('#lang');
  return locale[0].attributes['value'].value;
}

const dateRangeSettings_en = {
  popupOptions: {
    position: 'bottom left',
    forcePosition: true,
    lastResort: false,
    hideOnScroll: false
  },
  monthFirst: true,
  ampm: true,
  firstDayOfWeek: 0,
  text: {
    days: ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    months: ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    monthsShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    today: 'Today',
    now: 'Now',
    am: 'AM',
    pm: 'PM'
  }
};

const dateRangeSettings_fr = {
  popupOptions: {
    position: 'bottom left',
    forcePosition: true,
    lastResort: false,
    hideOnScroll: false
  },
  monthFirst: false,
  firstDayOfWeek: 1,
  ampm: false,
  text: {
    days: ['D', 'L', 'M', 'M', 'J', 'V', 'S'],
    months: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
    monthsShort: ['Janv', 'Févr', 'Mars', 'Avr', 'Mai', 'Juin', 'Juill', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'],
    today: 'Aujourd\'hui',
    now: 'Maintenant',
    am: 'AM',
    pm: 'PM'
  }
};

const hourToLabel_en = function(hour) {
  if (hour == 0) {
    return '0:00 AM';
  } else if(hour < 13) {
    return hour + ':00 AM';
  } else {
    return (hour-12) + ':00 PM';
  }
};

const hourToLabel_fr = function(hour) {
  return hour + 'h00';
};

const onCalendarChange = function(target, dateonly = true) {
  return function(date, text, other) {
    console.log("onCalendarChange");
    if (date) {
      if (dateonly) {
        target.val(date.toISOString().substr(0, 10));
      } else {
        target.val(date.toISOString());
      }
    }
    else {
      target.val("");
    }
    target.trigger("change");
  };
};

const submitParentForm = function() {
  console.log("apply filter");
  const form = $(this).parents('form');
  form.trigger("submit");
};

const onTimezoneChange = function(value, text, choice) {
  console.log("onTimezoneChange", value, text, choice);
  Turbolinks.visit('?tz=' + text);
};

const onRatingChanged = function(value) {
  console.log('onRatingChanged', $(this));
  const rating_input = $(this).parent().find('#comment_rating');
  console.log("rating_input", rating_input);
  console.log("onRatingChanged", value);
  rating_input.val(value);
};

$( document ).on('turbolinks:load', function() {
  console.log('on turbolinks:load');

  const show = $('#show_zoom_credentials');
  if (show) {
    show.on('click', function() {
      $('#zoom_credentials').removeClass('hidden');
      show.addClass('hidden');
    });
  }

  const force_reload_timezone = $('#force_reload_timezone');
  if (force_reload_timezone.length) {
    console.log('force_reload_timezone', force_reload_timezone.length);
    const local_settings = Intl.DateTimeFormat().resolvedOptions();
    if (local_settings) {
      Turbolinks.visit("?tz=" + local_settings.timeZone + "&locale=" + local_settings.locale);
    }
  }

  $('#live_event_modal.ui.modal').modal('show');

  const default_dropdown_settings = {
    fullTextSearch: 'exact',
    ignoreCase: true,
    ignoreSearchCase: true,
    ignoreDiacritics: true,
    match: 'text'
  }

  $('.defaultdd.dropdown').dropdown({
    ...default_dropdown_settings,
    forceSelection: false
  });

  const timezone_dropdown = $('.timezone.dropdown');
  timezone_dropdown.dropdown({
    ...default_dropdown_settings,
    //onChange: onTimezoneChange
  });
  console.log('timezone_dropdown', timezone_dropdown);

  
  const timezone_select_dropdown = $('#timezone_select');
  timezone_select_dropdown.dropdown({
    ...default_dropdown_settings,
    onChange: onTimezoneChange
  });
  console.log('timezone_select_dropdown', timezone_select_dropdown);

  $('.message .close').on('click', function() {
    $(this).closest('.message').transition('fade');
  });

  $('.special.cards .image').dimmer({
    on: 'hover'
  });

  // tours
  const dateRangeSettings = getLocale() == 'fr' ? dateRangeSettings_fr : dateRangeSettings_en;
  
  const datetimepicker_target = $('#event_date');
  $('.datetimepicker').calendar({
    ...dateRangeSettings,
    type: 'datetime',
    minTimeGap: 30,
    onChange: onCalendarChange(datetimepicker_target, false)
  });

  const start_date = $('#start_date');
  const start_date_val = start_date.val();
  $('#rangestart').calendar({
    ...dateRangeSettings,
    type: 'date',
    endCalendar: $('#rangeend'),
    onChange: onCalendarChange(start_date),
    initialDate: start_date_val ? new Date(start_date_val) : null
  });
  const end_date = $('#end_date');
  const end_date_val = end_date.val();
  $('#rangeend').calendar({
    ...dateRangeSettings,
    type: 'date',
    startCalendar: $('#rangestart'),
    onChange: onCalendarChange(end_date),
    initialDate: end_date_val ? new Date(end_date_val) : null,
  });
  
  const remove_right_links = $('.remove.right.link');
  remove_right_links.each(function () {
    const remove_link = $(this);
    const related_input = remove_link.prev('input');
    if (related_input.val() != "") {
      remove_link.css("visibility", "visible");
    }
  });
  remove_right_links.on("click", function(e) {
    const remove_link = $(this);
    //console.log("remove_link", remove_link);
    const related_input = remove_link.parent().parent();
    remove_link.hide();
    related_input.calendar("clear");
    //remove_link.prev('input').trigger("change"); 
  });

  const hourToLabel = getLocale() == 'fr' ? hourToLabel_fr : hourToLabel_en;

  const timeofday_begin_s_e = $('#timeofday_begin_s');
  const timeofday_end_s_e = $('#timeofday_end_s');
  const timeofday_begin_e = $('#timeofday_begin');
  const timeofday_end_e = $('#timeofday_end');

  const onTimeOfDayRangeMove = function(range, firstVal, secondVal) {
    console.log("onTimeOfDayRangeMove", firstVal, secondVal);
    if (firstVal > secondVal) {
      timeofday_begin_s_e.text(hourToLabel(secondVal));
      timeofday_end_s_e.text(hourToLabel(firstVal));
    } else {
      timeofday_begin_s_e.text(hourToLabel(firstVal));
      timeofday_end_s_e.text(hourToLabel(secondVal));
    }
  };

  const onTimeOfDayRangeChange = function(range, firstVal, secondVal) {
    if (firstVal > secondVal) {
      if (timeofday_begin_e.val() != secondVal) {
        timeofday_begin_e.val(secondVal);
        timeofday_begin_e.trigger('change');
      }
      if (timeofday_end_e.val() != firstVal) {
        timeofday_end_e.val(firstVal);
        timeofday_end_e.trigger('change');
      }
    } else {
      if (timeofday_begin_e.val() != firstVal) {
        timeofday_begin_e.val(firstVal);
        timeofday_begin_e.trigger('change');
      }
      if (timeofday_end_e.val() != secondVal) {
        timeofday_end_e.val(secondVal);
        timeofday_end_e.trigger('change');
      }
    }
  };

  $('#filter_by_date_form').on('submit', function() {
    // Find the input with id "file" in the context of
    // the form (hence the second "this" parameter) and
    // set it to be disabled
    $('#start_date_t', this).prop('disabled', true);
    $('#end_date_t', this).prop('disabled', true);
    $('#timeofday_range_slider').addClass("disabled");

    // return true to allow the form to submit
    return true;
  });

  const timeofday_begin = $("#timeofday_begin").val();
  const timeofday_end = $("#timeofday_end").val();
  const timeOfDayDefault = {
    min: 0,
    max: 24,
    step: 1,
    start: timeofday_begin ? parseInt(timeofday_begin, 10) : null,
    end: timeofday_end ? parseInt(timeofday_end, 10) : null,
    interpretLabel: hourToLabel,
    onMove: onTimeOfDayRangeMove,
    onChange: onTimeOfDayRangeChange
  };

  if (timeofday_begin && timeofday_end) {
    onTimeOfDayRangeMove(null, timeOfDayDefault.start, timeOfDayDefault.end);
  }

  $('#timeofday_range_slider').slider(timeOfDayDefault);

  // event_registrations
  $('.with_popup').popup();

  // https://github.com/turbolinks/turbolinks/issues/272
  // support remote get forms ... since turbolinks fails to do this properly
  $('form[method=get]').on('submit', function(e) {
    e.preventDefault();
    const form = $(this);
    const target = form.attr("action") + '?' + form.serialize();
    console.log("visit", target);
    Turbolinks.visit(target, { action: 'replace' });  
  });

  $(':input.submitOnChange').on('change', submitParentForm);
  $('.submitOnChange > select').on('change', submitParentForm);

  $('.ui.rating').rating({
    onRate: onRatingChanged
  });

  $('.button.editcomment').on('click', function() {
    const showonedit = $(this).parent().find('.showonedit');
    const hideonedit = $(this).parent().parent().find('.hideonedit');
    console.log('comment edit', showonedit, hideonedit);
    showonedit.removeClass('hidden');
    hideonedit.addClass('hidden');
  });
});

