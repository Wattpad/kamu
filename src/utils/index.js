'use strict';

// built-in/third-party modules
var QueryString = require( 'querystring' ),
            fs  = require('fs'),
    _           = require( 'lodash' );

// custom modules
var config      = require( '../config' ),
    log         = require( '../log' ),
    connStatus  = require( '../connection' );

// Placeholder image to show when 404
var placeholderImage = fs.readFileSync( __dirname + '/../../placeholders/404.jpg' );

/*
 * write the error response headers
 *
 * @param     res           object        response object
 * @param     statusCode    integer       numeric response code to write
 */
var writeHeadersWithStatusAndContentType = function( res, statusCode, contentType ) {
  var headers = {
    'expires': '0',
    'Cache-Control': 'no-cache, no-store, private, must-revalidate',
    'X-Frame-Options': config.defaultHeaders[ 'X-Frame-Options' ],
    'X-XSS-Protection': config.defaultHeaders[ 'X-XSS-Protection' ],
    'X-Content-Type-Options': config.defaultHeaders[ 'X-Content-Type-Options' ],
    'Content-Security-Policy': config.defaultHeaders[ 'Content-Security-Policy' ],
    'Strict-Transport-Security': config.defaultHeaders[ 'Strict-Transport-Security' ]
  };

  if ( contentType ) {
    headers[ 'Content-Type' ] = contentType;
  }

  res.writeHead( statusCode, headers );
};

/*
 * for backwards compatibility with legacy clients, respond with a placeholder image instead of a normal 404 response
 *
 * @param   object    res     http response object
 * @param   string    msg     404 message string
 * @param   object    url     url object
 */
var fourOhFour = function( res, msg, url ) {
  log.warn( msg + ': ' + ( ( url != null ? url.format() : void 0 ) || 'unknown' ) );

  writeHeadersWithStatusAndContentType( res, 200, 'image/jpeg' );
  finish( res, placeholderImage );
};
module.exports.fourOhFour = fourOhFour;

/*
 * respond with a 500 response
 *
 * @param   object    res     http response object
 * @param   string    msg     404 message string
 * @param   object    url     url object
 * @param   object    err     error object to log
 */
var fiveHundred = function( res, msg, url, err ) {
  log.error( msg + ': ' + ( ( url != null ? url.format() : void 0 ) || 'unknown' ), err );
  writeHeadersWithStatusAndContentType( res, 500 );
  return finish( res, 'Internal Error' );
};
module.exports.fiveHundred = fiveHundred;

/*
 * finish a response
 *
 * @param     object    res     http response object
 */
var finish = function( res, str ) {
  connStatus.close();

  if ( res.connection || !res.finished ) {
    return res.end( str );
  }
};
module.exports.finish = finish;


/*
 * returns a querystring object from a url instance
 *
 * @param     object      url       url object instance
 * @returns   object                querystring object
 */
var getQS = function( url ) {
  if ( url && ( url.query || url.search ) ) {
    if ( url.query ) {
      if ( typeof url.query === 'string' && url.query !== '' ) {
        return QueryString.parse( url.query );
      }
      else if ( typeof url.query === 'object' && _.keys( url.query ).length > 0 ) {
        return url.query;
      }
    }

    if ( url.search && url.search !== '' ) {
      return QueryString.parse( url.search );
    }
  }

  return;
};
module.exports.getQS = getQS;
