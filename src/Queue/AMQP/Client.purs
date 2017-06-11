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

  , publish

  , bindQueue

  , consume

  , ack
  ) where

-- Doc: http://www.squaremobius.net/amqp.node/channel_api.html


import Prelude

import Control.Monad.Aff (Aff, makeAff)
import Control.Monad.Aff.AVar (AVAR)
import Control.Monad.Aff.Console (CONSOLE)
import Control.Monad.Eff (Eff, kind Effect)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Error.Class (class MonadError, catchError, throwError)
import Data.ByteString (ByteString)
import Data.Either (Either(..), either)
import Data.Foreign (Foreign, toForeign)
import Data.Function.Uncurried (Fn2, Fn4, Fn5, runFn2, runFn4, runFn5)
import Data.Generic (class Generic, gShow)
import Data.Maybe (Maybe(..))
import Data.Monoid (mempty)
import Data.Newtype (class Newtype)
import Data.Options (Option, Options(..), opt, options, (:=))
import Data.Time.Duration (Milliseconds)
import Data.Unit (unit)
import Queue.AMQP.ConsumeOptions (ConsumeOptions)
import Queue.AMQP.PublishOptions (PublishOptions)



--------------------------------------------------------------------------------
foreign import data AMQP :: Effect

foreign import data Connection :: Type

foreign import data Channel :: Type

type AMQPEffects e a = Eff (amqp :: AMQP | e) a

type AMQPAction e a = (Error -> AMQPEffects e Unit) -> (a -> AMQPEffects e Unit) -> AMQPEffects e Unit

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

foreign import _connect
  :: forall eff
   . String
  -> ConnectOptions
  -> AMQPAction eff Connection

connect
  :: forall eff
   . String
  -> ConnectOptions
  -> Aff (amqp :: AMQP | eff) Connection
connect url options = makeAff $ _connect url options

foreign import _closeConnection
  :: forall eff
   . Connection
  -> AMQPAction eff Unit

closeConnection
  :: forall eff
   . Connection
  -> Aff (amqp :: AMQP | eff) Unit
closeConnection = makeAff <<< _closeConnection
--------------------------------------------------------------------------------

withChannel
  :: forall eff a
   . Connection
  -> (Channel -> Aff (amqp :: AMQP | eff) a)
  -> Aff (amqp :: AMQP | eff) a
withChannel conn kleisli =
  bracket (createChannel conn) closeChannel kleisli

foreign import _createChannel
  :: forall eff
   . Connection
  -> AMQPAction eff Channel

createChannel
  :: forall eff
   . Connection
  -> Aff (amqp :: AMQP | eff) Channel
createChannel = makeAff <<< _createChannel


foreign import _closeChannel
  :: forall eff
   . Channel
  -> AMQPAction eff Unit

closeChannel
  :: forall eff
   . Channel
  -> Aff (amqp :: AMQP | eff) Unit
closeChannel = makeAff <<< _closeChannel

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
{-
foreign import assertQueue
  :: forall eff
   . Channel
  -> Maybe Queue
  -> AssertQueueOptions
  -> Aff (amqp :: AMQP | eff) AssertQueueResponse
-}

--  -> AMQPAction e AssertQueueResponse


foreign import _assertQueue
  :: forall e
   . Channel
  -> Maybe Queue
  -> AssertQueueOptions
  -> AMQPAction e AssertQueueResponse

assertQueue :: forall eff
   . Channel
  -> Maybe Queue
  -> AssertQueueOptions
  -> Aff (amqp :: AMQP | eff) AssertQueueResponse

-- assertQueue chan queue opts = makeAff (_assertQueue chan queue opts)

assertQueue chan queue opts = makeAff (_assertQueue chan queue opts)

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

foreign import _assertExchange
  :: forall eff
   . Fn4 Channel
    Exchange
    ExchangeType
    AssertExchangeOptions
    (AMQPAction eff AssertExchangeResponse)

assertExchange
  :: forall eff
   . Channel
    -> Exchange
    -> ExchangeType
    -> AssertExchangeOptions
    -> (Aff (amqp :: AMQP | eff) AssertExchangeResponse)
assertExchange c e et o = makeAff $ (runFn4 _assertExchange) c e et o

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
foreign import _sendToQueue
  :: forall eff
   . Fn4 Channel
    Queue
    ByteString
    SendToQueueOptions
    (AMQPAction eff Boolean)

sendToQueue
  :: forall eff
   . Channel
  -> Queue
  -> ByteString
  -> SendToQueueOptions
  -> Aff (amqp :: AMQP | eff) Boolean
sendToQueue c q b o = makeAff $ (runFn4 _sendToQueue) c q b o

--------------------------------------------------------------------------------

foreign import _publish
  :: forall eff
   . Fn5 Channel
    Exchange
    RouteKey
    ByteString
    Foreign
    (AMQPAction eff Boolean)

publish
  :: forall eff
   . Channel
  -> Exchange
  -> RouteKey
  -> ByteString
  -> (Options PublishOptions)
  -> Aff (amqp :: AMQP | eff) Boolean
publish c e k b o = makeAff $ (runFn5 _publish) c e k b (options o)


--------------------------------------------------------------------------------


{-
Assert a routing path from an exchange to a queue: the exchange named by source will relay messages to the queue named, according to the type of the exchange and the pattern given. The RabbitMQ tutorials give a good account of how routing works in AMQP.

args is an object containing extra arguments that may be required for the particular exchange type (for which, see your server's documentation). It may be omitted if it's the last argument, which is equivalent to an empty object.

The server reply has no fields.
-}

foreign import _bindQueue
  :: forall eff
   . Fn5 Channel
  Queue
  Exchange
  Pattern
  Foreign -- args
  (AMQPAction eff Unit)

bindQueue :: forall eff
   . Channel
  -> Queue
  -> Exchange
  -> Pattern
  -> Foreign -- args
  -> Aff (amqp :: AMQP | eff) Unit
bindQueue c q e p f = makeAff $ (runFn5 _bindQueue) c q e p f

--------------------------------------------------------------------------------

foreign import _consume
  :: forall eff
    . Fn4
    Channel
    Queue
    (forall e . Maybe Message -> Eff (amqp :: AMQP, avar :: AVAR | e) Unit)  
    (Maybe Foreign)
    (AMQPAction eff Unit)

consume :: forall eff
    . Channel
    -> Queue
    -> (forall e . Maybe Message -> Eff (amqp :: AMQP, avar :: AVAR | e) Unit)  
    -> Maybe (Options ConsumeOptions)
    -> Aff (amqp :: AMQP | eff) Unit

consume c q cb o = makeAff $ (runFn4 _consume) c q cb (map options o)

--------------------------------------------------------------------------------

foreign import _ack
  :: forall eff
   . Fn2
    Channel
    Message
    (AMQPAction eff Unit)

ack :: forall eff
    . Channel
    -> Message
    -> Aff (amqp :: AMQP | eff) Unit
ack c m = makeAff $ (runFn2 _ack) c m


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
