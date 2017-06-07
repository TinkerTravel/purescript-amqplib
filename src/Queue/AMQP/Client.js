'use strict';

var amqplib = require('amqplib/callback_api');
var Data_Maybe = require('../Data.Maybe');

exports.connect = function (url) {
  return function (psOptions) {
    var jsOptions = {};
    return function (onSuccess, onError) {
      amqplib.connect(url, jsOptions, function (err, conn) {
        if (err !== null) {
          onError(err);
          return;
        }
        onSuccess(conn);
      });
    };
  };
};

exports.closeConnection = function (conn) {
  return function (onSuccess, onError) {
    conn.close(function (err) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess({});
    });
  };
};

exports.createChannel = function (conn) {
  return function (onSuccess, onError) {
    conn.createChannel(function (err, chan) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess(chan);
    });
  };
};

exports.closeChannel = function (chan) {
  return function (onSuccess, onError) {
    chan.close(function (err) {
      if (err !== null) {
        onError(err);
        return;
      }
      onSuccess({});
    });
  };
};

exports.assertQueue = function (chan) {
  return function (psQueue) {
    var jsQueue = null;
    if (psQueue instanceof Data_Maybe.Just) {
      jsQueue = psQueue.value0;
    }
    return function (psOptions) {
      var jsOptions = {};
      jsOptions.exclusive = psOptions.exclusive;
      jsOptions.durable = psOptions.durable;
      return function (onSuccess, onError) {
        chan.assertQueue(jsQueue, jsOptions, function (err, ok) {
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

exports.assertExchange = function (chan) {
  return function (exchange) {
    return function (exchangeType) {
      return function (psOptions) {
        var jsOptions = psOptions; // ?
        return function (onSuccess, onError) {
          chan.assertExchange(exchange, exchangeType, jsOptions, function (err, ok) {
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
};

exports.sendToQueue = function (chan) {
  return function (queue) {
    return function (content) {
      return function (psOptions) {
        var jsOptions = {};
        if (psOptions.expiration instanceof Data_Maybe.Just) {
          jsOptions.expiration = psOptions.expiration.value0;
        }
        return function (onSuccess, onError) {
          var sent = chan.sendToQueue(queue, content, jsOptions);
          onSuccess(sent);
        };
      };
    };
  };
};

exports.publish = function (chan) {
  return function (exchange) {
    return function (routeKey) {
      return function (content) {
        return function (psOptions) {
          var options = ["expiration", "userId", "CC", "priority", "persistent", "mandatory", "BCC", "contentType", "contentEncoding", "headers", "correlationId", "replyTo", "messageId", "timestamp", "type", "appId"];
          var jsOptions = {};
          var len = options.length;
          for (var i = 0; i < len; i++) {
            var o = options[i];
            var po = psOptions[o];
            if (po && po instanceof Data_Maybe.Just) {
              jsOptions[o] = po.value0;
            }
          }
          return function (onSuccess, onError) {
            var sent = chan.publish(exchange, routeKey, content, jsOptions);
            onSuccess(sent);
          };
        };
      };
    };
  };
};

exports.bindQueue = function (chan) {
  return function (queue) {
    return function (exchange) {
      return function (pattern) {
        return function (args) {
          return function (onSuccess, onError) {
            chan.bindQueue(queue, exchange, pattern, args, function (err, ok) {
              if (err) {
                onError(err)
              } else {
                onSuccess(ok);
              }
            });
          };
        };
      };
    };
  };
};
