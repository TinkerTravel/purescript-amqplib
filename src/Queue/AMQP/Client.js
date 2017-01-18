'use strict';

var amqplib = require('amqplib/callback_api');
var Data_Maybe = require('../Data.Maybe');

exports.connect = function(url) {
  return function(psOptions) {
    var jsOptions = {};
    return function(onSuccess, onError) {
      amqplib.connect(url, jsOptions, function(err, conn) {
        if (err !== null) {
          onError(err);
          return;
        }
        onSuccess(conn);
      });
    };
  };
};

exports.closeConnection = function(conn) {
  return function(onSuccess, onError) {
    conn.close(function(err) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess({});
    });
  };
};

exports.createChannel = function(conn) {
  return function(onSuccess, onError) {
    conn.createChannel(function(err, chan) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess(chan);
    });
  };
};

exports.closeChannel = function(chan) {
  return function(onSuccess, onError) {
    chan.close(function(err) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess({});
    });
  };
};

exports.assertQueue = function(chan) {
  return function(psQueue) {
    var jsQueue = null;
    if (psQueue instanceof Data_Maybe.Just) {
      jsQueue = psQueue.value0;
    }
    return function(psOptions) {
      var jsOptions = {};
      jsOptions.exclusive = psOptions.exclusive;
      jsOptions.durable   = psOptions.durable;
      return function(onSuccess, onError) {
        chan.assertQueue(jsQueue, jsOptions, function(err, ok) {
          if (err != null) {
            onError(err);
            return;
          }
          onSuccess(ok);
        });
      };
    };
  };
};

exports.sendToQueue = function(chan) {
  return function(queue) {
    return function(content) {
      return function(psOptions) {
        var jsOptions = {};
        if (psOptions.expiration instanceof Data_Maybe.Just) {
          jsOptions.expiration = psOptions.expiration.value0;
        }
        return function(onSuccess, onError) {
          var sent = chan.sendToQueue(queue, content, jsOptions);
          onSuccess(sent);
        };
      };
    };
  };
};