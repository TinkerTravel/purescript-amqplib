module Queue.AMQP.SendToQueueOptions where

  -- Used by RabbitMQ and sent on to consumers:

import Data.Monoid (mempty)
import Data.Options (Option, Options, opt)
import Data.Time.Duration (Milliseconds)
  
  -- Used by RabbitMQ and sent on to consumers:
foreign import data SendToQueueOptions :: Type

expiration :: Option SendToQueueOptions Milliseconds
expiration = opt "expiration"

defaultSendToQueueOptions :: Options SendToQueueOptions
defaultSendToQueueOptions = mempty
