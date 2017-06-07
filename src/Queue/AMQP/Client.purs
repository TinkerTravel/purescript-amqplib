module Queue.AMQP.Client
  ( AMQP
  , Connection
  , Channel
  , Queue(..)
  , Exchange(..)
  , ExchangeType(..)
  , RouteKey(..)
  , Pattern(..)
  , Message(..)

  , ConnectOptions
  , defaultConnectOptions
  , withConnection

  , withChannel

  , AssertQueueOptions
  , defaultAssertQueueOptions
  , AssertQueueResponse
  , assertQueue

  , AssertExchangeOptions
  , AssertExchangeOptionsArguments
  , defaultAssertExchangeOptions
  , AssertExchangeResponse
  , assertExchange

  , SendToQueueOptions
  , defaultSendToQueueOptions
  , sendToQueue

  , PublishOptions
  , defaultPublishOptions
  , publish

  , bindQueueImpl
  , bindQueue

  , ConsumeOptions
  , consumeImpl
  , consume

  , ackImpl
  , ack
  ) where

-- Doc: http://www.squaremobius.net/amqp.node/channel_api.html


import Prelude

import Control.Monad.Aff (Aff)
import Control.Monad.Aff.AVar (AVAR)
import Control.Monad.Aff.Console (CONSOLE)
import Control.Monad.Eff (Eff, kind Effect)
import Control.Monad.Error.Class (class MonadError, catchError, throwError)
import Data.ByteString (ByteString)
import Data.Either (Either(..), either)
import Data.Foreign (Foreign, toForeign)
import Data.Function.Uncurried (Fn2, Fn4, Fn5, runFn2, runFn4, runFn5)
import Data.Generic (class Generic, gShow)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Time.Duration (Milliseconds)
import Data.Unit (unit)


--------------------------------------------------------------------------------
foreign import data AMQP :: Effect

foreign import data Connection :: Type

foreign import data Channel :: Type

newtype Queue = Queue String
derive newtype instance eqQueue :: Eq Queue
derive newtype instance ordQueue :: Ord Queue
derive instance newtypeQueue :: Newtype Queue _

newtype Exchange = Exchange String
derive newtype instance eqExchange :: Eq Exchange
derive newtype instance ordExchange :: Ord Exchange
derive instance newtypeExchange :: Newtype Exchange _

newtype Pattern = Pattern String
derive newtype instance eqPattern :: Eq Pattern
derive newtype instance ordPattern :: Ord Pattern
derive instance newtypePattern :: Newtype Pattern _


newtype RouteKey = RouteKey String
derive newtype instance eqRouteKey :: Eq RouteKey
derive newtype instance ordRouteKey :: Ord RouteKey
derive instance newtypeRouteKey :: Newtype RouteKey _

newtype ExchangeType = ExchangeType String
derive newtype instance eqExchangeType :: Eq ExchangeType
derive newtype instance ordExchangeType :: Ord ExchangeType
derive instance newtypeExchangeType :: Newtype ExchangeType _


type Message =
  { fields :: Foreign
   {- consumerTag: 'amq.ctag-V5Byeogawjg91OQhMklbwQ',
     deliveryTag: 11,
     redelivered: false,
     exchange: 'exchangeOne',
     routingKey: 'key' -}
  , properties :: Foreign
{-   { contentType: undefined,
     contentEncoding: undefined,
     headers: {},
     deliveryMode: undefined,
     priority: undefined,
     correlationId: undefined,
     replyTo: undefined,
     expiration: undefined,
     messageId: undefined,
     timestamp: undefined,
     type: undefined,
     userId: undefined,
     appId: undefined,
     clusterId: undefined -}
  , content :: ByteString
}


--------------------------------------------------------------------------------

type ConnectOptions =
  {}

defaultConnectOptions :: ConnectOptions
defaultConnectOptions =
  {}

-- | It is recommended you always derive options from `defaultConnectOptions`
-- | using record updates. This way more options can be added later without
-- | breaking your code.
withConnection
  :: forall eff a
   . String
  -> ConnectOptions
  -> (Connection -> Aff (amqp :: AMQP | eff) a)
  -> Aff (amqp :: AMQP | eff) a
withConnection url options kleisli =
  bracket (connect url options) closeConnection kleisli

foreign import connect
  :: forall eff
   . String
  -> ConnectOptions
  -> Aff (amqp :: AMQP | eff) Connection

foreign import closeConnection
  :: forall eff
   . Connection
  -> Aff (amqp :: AMQP | eff) Unit

--------------------------------------------------------------------------------

withChannel
  :: forall eff a
   . Connection
  -> (Channel -> Aff (amqp :: AMQP | eff) a)
  -> Aff (amqp :: AMQP | eff) a
withChannel conn kleisli =
  bracket (createChannel conn) closeChannel kleisli

foreign import createChannel
  :: forall eff
   . Connection
  -> Aff (amqp :: AMQP | eff) Channel

foreign import closeChannel
  :: forall eff
   . Channel
  -> Aff (amqp :: AMQP | eff) Unit

--------------------------------------------------------------------------------

type AssertQueueOptions =
  { exclusive :: Boolean
  , durable   :: Boolean
  }

defaultAssertQueueOptions :: AssertQueueOptions
defaultAssertQueueOptions =
  { exclusive: false
  , durable:   true
  }

type AssertQueueResponse =
  { queue         :: Queue
  , messageCount  :: Int
  , consumerCount :: Int
  }

-- | It is recommended you always derive options from
-- | `defaultAssertQueueOptions` using record updates. This way more options
-- | can be added later without breaking your code.
foreign import assertQueue
  :: forall eff
   . Channel
  -> Maybe Queue
  -> AssertQueueOptions
  -> Aff (amqp :: AMQP | eff) AssertQueueResponse


--------------------------------------------------------------------------------

type AssertExchangeOptionsArguments = {}

type AssertExchangeOptions =
  { durable :: Boolean -- if true, the exchange will survive broker restarts. Defaults to true.
  , internal:: Boolean -- if true, messages cannot be published directly to the exchange (i.e., it can only be the target of bindings, or possibly create messages ex-nihilo). Defaults to false.
  ,  autoDelete:: Boolean -- if true, the exchange will be destroyed once the number of bindings for which it is the source drop to zero. Defaults to false.
  ,  alternateExchange:: Exchange -- an exchange to send messages to if this exchange can't route them to any queues.
  ,  arguments:: Foreign
  }

defaultAssertExchangeOptions :: AssertExchangeOptions
defaultAssertExchangeOptions =
  { durable : true
  , internal: false
  , autoDelete: false
  , alternateExchange: Exchange ""
  , arguments: toForeign {}
  }

type AssertExchangeResponse = {
  exchange :: Exchange
}

data AssertExchangeResponseData = AssertExchangeResponse AssertExchangeResponse

foreign import assertExchangeImpl
  :: forall eff
   . Fn4 Channel
    Exchange
    ExchangeType
    AssertExchangeOptions
    (Aff (amqp :: AMQP | eff) AssertExchangeResponse)

assertExchange
  :: forall eff
   . Channel
  -> Exchange
  -> ExchangeType
  -> AssertExchangeOptions
  -> Aff (amqp :: AMQP | eff) AssertExchangeResponse
assertExchange = runFn4 assertExchangeImpl

--------------------------------------------------------------------------------

type SendToQueueOptions =
  { expiration :: Maybe Milliseconds
  }

defaultSendToQueueOptions :: SendToQueueOptions
defaultSendToQueueOptions =
  { expiration: Nothing
  }

-- | It is recommended you always derive options from
-- | `defaultSendToQueueOptions` using record updates. This way more options
-- | can be added later without breaking your code.
foreign import sendToQueueImpl
  :: forall eff
   . Fn4 Channel
    Queue
    ByteString
    SendToQueueOptions
    (Aff (amqp :: AMQP | eff) Boolean)

sendToQueue
  :: forall eff
   . Channel
  -> Queue
  -> ByteString
  -> SendToQueueOptions
  -> Aff (amqp :: AMQP | eff) Boolean
sendToQueue = runFn4 sendToQueueImpl

--------------------------------------------------------------------------------

type PublishOptions = {
    -- Used by RabbitMQ and sent on to consumers:

    expiration :: Maybe String -- if supplied, the message will be discarded from a queue once it's been there longer than the given number of milliseconds. In the specification this is a string; numbers supplied here will be coerced to strings for transit.

  , userId :: Maybe String  -- If supplied, RabbitMQ will compare it to the username supplied when opening the connection, and reject messages for which it does not match.

  , "CC" :: Maybe (Array String) -- an array of routing keys as strings; messages will be routed to these routing keys in addition to that given as the routingKey parameter. This will override any value given for CC in the headers parameter. NB The property names CC and BCC are case-sensitive.

  , priority :: Maybe Int -- (positive integer): a priority for the message; ignored by versions of RabbitMQ older than 3.5.0, or if the queue is not a priority queue (see maxPriority above).

  , persistent :: Maybe Boolean -- If truthy, the message will survive broker restarts provided it's in a queue that also survives restarts. Corresponds to, and overrides, the property deliveryMode.

  -- Used by RabbitMQ but not sent on to consumers:

  , mandatory :: Maybe Boolean -- if true, the message will be returned if it is not routed to a queue (i.e., if there are no bindings that match its routing key).

  , "BCC" :: Maybe (Array String) -- like CC, except that the value will not be sent in the message headers to consumers.

  -- Ignored by RabbitMQ (but may be useful for applications):

  , contentType :: Maybe String -- a MIME type for the message content

  , contentEncoding :: Maybe String --  a MIME encoding for the message content

  , headers :: Maybe Foreign -- (object): application specific headers to be carried along with the message content. The value as sent may be augmented by extension-specific fields if they are given in the parameters, for example, 'CC', since these are encoded as message headers; the supplied value won't be mutated

  , correlationId :: Maybe String -- usually used to match replies to requests, or similar

  , replyTo :: Maybe String -- often used to name a queue to which the receiving application must send replies, in an RPC scenario (many libraries assume this pattern)

  , messageId :: Maybe String -- arbitrary application-specific identifier for the message

  , timestamp :: Maybe Number -- a timestamp for the message

  , type :: Maybe String -- an arbitrary application-specific type for the message

  , appId :: Maybe String -- an arbitrary identifier for the originating application
}

defaultPublishOptions :: PublishOptions
defaultPublishOptions = {
    expiration : Nothing
  , userId : Nothing
  , "CC" : Nothing
  , priority : Nothing
  , persistent : Nothing
  , mandatory : Nothing
  , "BCC" : Nothing
  , contentType :Nothing
  , contentEncoding :Nothing
  , headers :Nothing
  , correlationId :Nothing
  , replyTo :Nothing
  , messageId :Nothing
  , timestamp :Nothing
  , "type" :Nothing
  , appId : Nothing
}

foreign import publishImpl
  :: forall eff
   . Fn5 Channel
    Exchange
    RouteKey
    ByteString
    PublishOptions
    (Aff (amqp :: AMQP | eff) Boolean)

publish
  :: forall eff
   . Channel
  -> Exchange
  -> RouteKey
  -> ByteString
  -> PublishOptions
  -> Aff (amqp :: AMQP | eff) Boolean
publish = runFn5 publishImpl

--------------------------------------------------------------------------------


{-
Assert a routing path from an exchange to a queue: the exchange named by source will relay messages to the queue named, according to the type of the exchange and the pattern given. The RabbitMQ tutorials give a good account of how routing works in AMQP.

args is an object containing extra arguments that may be required for the particular exchange type (for which, see your server's documentation). It may be omitted if it's the last argument, which is equivalent to an empty object.

The server reply has no fields.
-}

foreign import bindQueueImpl
  :: forall eff
   . Fn5 Channel
  Queue
  Exchange
  Pattern
  Foreign -- args
  (Aff (amqp :: AMQP | eff) Unit)

bindQueue :: forall eff
   . Channel
  -> Queue
  -> Exchange
  -> Pattern
  -> Foreign -- args
  -> Aff (amqp :: AMQP | eff) Unit
bindQueue = runFn5 bindQueueImpl

--------------------------------------------------------------------------------

type ConsumeOptions = 
  { consumerTag :: Maybe String --  a name which the server will use to distinguish message deliveries for the consumer; mustn't be already in use on the channel. It's usually easier to omit this, in which case the server will create a random name and supply it in the reply.

  , noLocal :: Maybe Boolean -- in theory, if true then the broker won't deliver messages to the consumer if they were also published on this connection; RabbitMQ doesn't implement it though, and will ignore it. Defaults to false.

  , noAck :: Maybe Boolean -- if true, the broker won't expect an acknowledgement of messages delivered to this consumer; i.e., it will dequeue messages as soon as they've been sent down the wire. Defaults to false (i.e., you will be expected to acknowledge messages).

  , exclusive :: Maybe Boolean -- if true, the broker won't let anyone else consume from this queue; if there already is a consumer, there goes your channel (so usually only useful if you've made a 'private' queue by letting the server choose its name).

  , priority :: Maybe Int -- gives a priority to the consumer; higher priority consumers get messages in preference to lower priority consumers. See this RabbitMQ extension's documentation

  , arguments :: Maybe Foreign -- arbitrary arguments. Go to town.  
}

defaultConsumeOptions :: ConsumeOptions
defaultConsumeOptions = 
  { consumerTag : Nothing
  , noLocal : Nothing
  , noAck : Nothing
  , exclusive : Nothing
  , priority : Nothing
  , arguments : Nothing
}

foreign import consumeImpl
  :: forall eff
    . Fn4
    Channel
    Queue
    (forall e . Maybe Message -> Eff (amqp :: AMQP, avar :: AVAR | e) Unit)  
    (Maybe ConsumeOptions)
    (Aff (amqp :: AMQP | eff) Unit)

consume :: forall eff
    . Channel
    -> Queue
    -> (forall e . Maybe Message -> Eff (amqp :: AMQP, avar :: AVAR | e) Unit)  
    -> Maybe ConsumeOptions
    -> Aff (amqp :: AMQP | eff) Unit

consume = runFn4 consumeImpl

--------------------------------------------------------------------------------

foreign import ackImpl
  :: forall eff
   . Fn2
    Channel
    Message
    (Aff (amqp :: AMQP | eff) Unit)

ack :: forall eff
    . Channel
    -> Message
    -> Aff (amqp :: AMQP | eff) Unit
ack = runFn2 ackImpl 


--------------------------------------------------------------------------------

bracket
  :: forall error monad resource result
   . (MonadError error monad)
  => monad resource
  -> (resource -> monad Unit)
  -> (resource -> monad result)
  -> monad result
bracket acquire release kleisli = do
  resource <- acquire
  result <- (Right <$> kleisli resource) `catchError` (pure <<< Left)
  release resource
  either throwError pure result
