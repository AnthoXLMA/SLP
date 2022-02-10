const { environment } = require('@rails/webpacker')

module.exports = environment

const webpack = require("webpack")

environment.plugins.append("Provide", new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Popper: ['popper.js', 'default']
}))

environment.plugins.prepend('DefinePlugin',
  new webpack.DefinePlugin({
    'GIT_SHA1': JSON.stringify(process.env.GIT_SHA1),
    'SENTRY_DSN': JSON.stringify(process.env.SENTRY_DSN)
  })
)
