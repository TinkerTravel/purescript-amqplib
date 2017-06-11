module Queue.AMQP.AssertExchangeOptions where
  

import Data.Foreign (Foreign, toForeign)
import Data.Monoid ((<>))
import Data.Options (Option, Options, opt, (:=))
import Queue.AMQP.Types (Exchange(..))

  -- Used by RabbitMQ and sent on to consumers:
foreign import data AssertExchangeOptions :: Type


durable :: Option AssertExchangeOptions Boolean
durable = opt "durable"  -- if true, the exchange will survive broker restarts. Defaults to true.

internal:: Option AssertExchangeOptions Boolean
internal = opt "" -- if true, messages cannot be published directly to the exchange (i.e., it can only be the target of bindings, or possibly create messages ex-nihilo). Defaults to false.

autoDelete :: Option AssertExchangeOptions Boolean
autoDelete = opt "autoDelete"  -- if true, the exchange will be destroyed once the number of bindings for which it is the source drop to zero. Defaults to false.

alternateExchange :: Option AssertExchangeOptions Exchange
alternateExchange = opt "alternateExchange" -- an exchange to send messages to if this exchange can't route them to any queues.

arguments :: Option AssertExchangeOptions Foreign
arguments = opt "arguments"


defaultAssertExchangeOptions :: Options AssertExchangeOptions
defaultAssertExchangeOptions =
      durable := true
  <>  internal:= false
  <>  autoDelete := false
  <>  alternateExchange := Exchange ""
  <>  arguments := toForeign {}
