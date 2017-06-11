module Queue.AMQP.AssertQueueOptions where


import Data.Monoid ((<>))
import Data.Options (Option, Options, opt, (:=))

  -- Used by RabbitMQ and sent on to consumers:
foreign import data AssertQueueOptions :: Type

exclusive :: Option AssertQueueOptions Boolean
exclusive = opt "exclusive"

durable :: Option AssertQueueOptions Boolean
durable = opt "durable"

defaultAssertQueueOptions :: Options AssertQueueOptions
defaultAssertQueueOptions =
      exclusive := false
  <>  durable   := true
