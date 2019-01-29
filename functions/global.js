// https://stackoverflow.com/questions/5447771/node-js-global-variables
const functions = require('firebase-functions');

// 1.4 leagues
// 1.5 event.js, league.js, action.js, push.js
const API_VERSION = 1.0
const BUILD_VERSION = 1 // for internal tracking

// TO TOGGLE BETWEEN DEV AND PROD: change this to .dev or .prod for functions:config variables to be correct
const config = functions.config().dev

module.exports = {
	isDev : config.environment == "dev",
	apiKey : config.firebase.api_key,
	stripeToken : config.stripe.token,
	apiVersion : API_VERSION,
	buildVersion: BUILD_VERSION
}