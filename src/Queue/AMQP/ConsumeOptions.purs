module Queue.AMQP.ConsumeOptions where

import Data.Foreign (Foreign)
import Data.Monoid (mempty)
import Data.Options (Option, Options, opt)


  -- Used by RabbitMQ and sent on to consumers:
foreign import data ConsumeOptions :: Type


consumerTag :: Option ConsumeOptions String
consumerTag = opt "consumerTag" --  a name which the server will use to distinguish message deliveries for the consumer; mustn't be already in use on the channel. It's usually easier to omit this, in which case the server will create a random name and supply it in the reply.

noLocal:: Option ConsumeOptions Boolean
noLocal = opt "noLocal" -- in theory, if true then the broker won't deliver messages to the consumer if they were also published on this connection; RabbitMQ doesn't implement it though, and will ignore it. Defaults to false.

noAck:: Option ConsumeOptions Boolean
noAck = opt "noAck" -- if true, the broker won't expect an acknowledgement of messages delivered to this consumer; i.e., it will dequeue messages as soon as they've been sent down the wire. Defaults to false (i.e., you will be expected to acknowledge messages).

exclusive:: Option ConsumeOptions Boolean
exclusive = opt "exclusive" -- if true, the broker won't let anyone else consume from this queue; if there already is a consumer, there goes your channel (so usually only useful if you've made a 'private' queue by letting the server choose its name).

priority:: Option ConsumeOptions Int
priority = opt "priority" -- gives a priority to the consumer; higher priority consumers get messages in preference to lower priority consumers. See this RabbitMQ extension's documentation

arguments:: Option ConsumeOptions Foreign
arguments = opt "arguments" -- arbitrary arguments. Go to town.  


defaultConsumeOptions :: (Options ConsumeOptions)
defaultConsumeOptions = mempty
