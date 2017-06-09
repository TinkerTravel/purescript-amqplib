'use strict';

var amqplib = require('amqplib/callback_api');
var Data_Maybe = require('../Data.Maybe');

var extractVars = function (options, keys) {
  var res = {};
  var len = keys.length;
  for (var i = 0; i < len; i++) {
    var o = keys[i];
    var po = options[o];
    if (po) {
      if (po instanceof Data_Maybe.Just) {
        res[o] = po.value0;
      } else if (po instanceof Data_Maybe.Nothing) {
      } else {
        res[o] = po;
      }
    }
  }
  return res;
}

exports._connect = function (url) {
  return function (psOptions) {
    var jsOptions = {};
    return function (onError) {
      return function (onSuccess) {
        return function () {
          amqplib.connect(url, jsOptions, function (err, conn) {
            if (err !== null) {
              onError(err)();
            } else {
              onSuccess(conn)();
            }
          });
        };
      };
    };
  };
};

exports._closeConnection = function (conn) {
  return function (onError) {
    return function (onSuccess) {
      return function () {
        conn.close(function (err) {
          if (err !== null) {
            onError(err)();
          } else {
            onSuccess({})();
          }
        });
      };
    };
  };
};

exports._createChannel = function (conn) {
  return function (onError) {
    return function (onSuccess) {
      return function () {
        conn.createChannel(function (err, chan) {
          if (err !== null) {
            onError(err)();
          } else {
            onSuccess(chan)();
          }
        });
      };
    };
  };
};

exports._closeChannel = function (chan) {
  return function (onError) {
    return function (onSuccess) {
      return function () {
        chan.close(function (err) {
          if (err !== null) {
            onError(err)();
          } else {
            onSuccess({})();
          }
        });
      };
    };
  };
};

exports._assertQueue = function (chan) {
  return function (psQueue) {
    var jsQueue = null;
    if (psQueue instanceof Data_Maybe.Just) {
      jsQueue = psQueue.value0;
    }
    return function (psOptions) {
      var jsOptions = {};
      jsOptions.exclusive = psOptions.exclusive;
      jsOptions.durable = psOptions.durable;
      return function (onError) {
        return function (onSuccess) {
          return function () {
            chan.assertQueue(jsQueue, jsOptions, function (err, ok) {
              if (err != null) {
                onError(err)();
              } else {
                onSuccess(ok)();
              }
            });
          };
        };
      };
    };
  };
};

exports._assertExchange = function (chan, exchange, exchangeType, psOptions) {
  var jsOptions = psOptions; // ?
  return function (onError) {
    return function (onSuccess) {
      return function () {
        chan.assertExchange(exchange, exchangeType, jsOptions, function (err, ok) {
          if (err != null) {
            onError(err)();
          } else {
            onSuccess(ok)();
          }
        });
      };
    };
  };
};

exports._sendToQueue = function (chan, queue, content, psOptions) {
  var jsOptions = {};
  if (psOptions.expiration instanceof Data_Maybe.Just) {
    jsOptions.expiration = psOptions.expiration.value0;
  }
  return function (onError) {
    return function (onSuccess) {
      return function () {
        var sent = chan.sendToQueue(queue, content, jsOptions);
        onSuccess(sent)();
      };
    };
  };
};

var publishOptionsKeys = ["expiration", "userId", "CC", "priority", "persistent", "mandatory", "BCC", "contentType", "contentEncoding", "headers", "correlationId", "replyTo", "messageId", "timestamp", "type", "appId"];

exports._publish = function (chan, exchange, routeKey, content, psOptions) {
  var jsOptions = extractVars(psOptions, publishOptionsKeys);

  return function (onError) {
    return function (onSuccess) {
      return function () {
        var sent = chan.publish(exchange, routeKey, content, jsOptions);
        onSuccess(sent)();
      };
    };
  };
};

exports._bindQueue = function (chan, queue, exchange, pattern, args) {
  return function (onError) {
    return function (onSuccess) {
      return function () {
        chan.bindQueue(queue, exchange, pattern, args, function (err, ok) {
          if (err) {
            onError(err)();
          } else {
            onSuccess(ok)();
          }
        });
      };
    };
  };
};

var consumeOptionsKeys = ["consumerTag", "noLocal", "noAck", "exclusive", "priority", "arguments"];

exports._consume = function (chan, queue, cb, psOptions) {
  var jsOptions = {};

  if (psOptions instanceof Data_Maybe.Just) {
    jsOptions = extractVars(psOptions.value0, consumeOptionsKeys);
  }

  return function (onError) {
    return function (onSuccess) {
      return function () {
        chan.consume(queue, function (msg) {
          if (msg) {
            cb(new Data_Maybe.Just(msg))();
          } else {
            cb(new Data_Maybe.Nothing.value)();
          }
        }, jsOptions, function (err, ok) {
          if (err) {
            onError(err)();
          } else {
            onSuccess(ok)();
          }
        })
      }
    }
  }
}


exports._ack = function (chan, message) {
  return function (onError) {
    return function (onSuccess) {
      return function () {
        chan.ack(message);
        onSuccess()();
      };
    };
  };
}
