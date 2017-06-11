module Queue.AMQP.Client
  ( AMQP
  , Connection
  , Channel

  , ConnectOptions
  , defaultConnectOptions
  , withConnection

  , withChannel

  , AssertQueueResponse
  , assertQueue

  , AssertExchangeResponse
  , assertExchange

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
import Control.Monad.Eff (Eff, kind Effect)
import Control.Monad.Eff.Exception (Error)
import Control.Monad.Error.Class (class MonadError, catchError, throwError)
import Data.ByteString (ByteString)
import Data.Either (Either(..), either)
import Data.Foreign (Foreign)
import Data.Function.Uncurried (Fn2, Fn4, Fn5, runFn2, runFn4, runFn5)
import Data.Maybe (Maybe)
import Data.Options (Options, options)
import Queue.AMQP.AssertExchangeOptions (AssertExchangeOptions)
import Queue.AMQP.AssertQueueOptions (AssertQueueOptions)
import Queue.AMQP.ConsumeOptions (ConsumeOptions)
import Queue.AMQP.PublishOptions (PublishOptions)
import Queue.AMQP.SendToQueueOptions (SendToQueueOptions)
import Queue.AMQP.Types (Exchange, ExchangeType, Message, Pattern, Queue, RouteKey)

--------------------------------------------------------------------------------
foreign import data AMQP :: Effect

foreign import data Connection :: Type

foreign import data Channel :: Type

type AMQPEffects e a = Eff (amqp :: AMQP | e) a

type AMQPAction e a = (Error -> AMQPEffects e Unit) -> (a -> AMQPEffects e Unit) -> AMQPEffects e Unit


--------------------------------------------------------------------------------

type ConnectOptions =
  {}

defaultConnectOptions :: ConnectOptions
defaultConnectOptions =
  {}

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

type AssertQueueResponse =
  { queue         :: Queue
  , messageCount  :: Int
  , consumerCount :: Int
  }

foreign import _assertQueue
  :: forall e
   . Channel
  -> Maybe Queue
  -> Foreign
  -> AMQPAction e AssertQueueResponse

assertQueue :: forall eff
   . Channel
  -> Maybe Queue
  -> (Options AssertQueueOptions)
  -> Aff (amqp :: AMQP | eff) AssertQueueResponse

-- assertQueue chan queue opts = makeAff (_assertQueue chan queue opts)

assertQueue chan queue opts = makeAff (_assertQueue chan queue (options opts))

--------------------------------------------------------------------------------

type AssertExchangeResponse = {
  exchange :: Exchange
}

data AssertExchangeResponseData = AssertExchangeResponse AssertExchangeResponse

foreign import _assertExchange
  :: forall eff
   . Fn4 Channel
    Exchange
    ExchangeType
    Foreign
    (AMQPAction eff AssertExchangeResponse)

assertExchange
  :: forall eff
   . Channel
    -> Exchange
    -> ExchangeType
    -> Options AssertExchangeOptions
    -> (Aff (amqp :: AMQP | eff) AssertExchangeResponse)
assertExchange c e et o = makeAff $ (runFn4 _assertExchange) c e et (options o)

--------------------------------------------------------------------------------

foreign import _sendToQueue
  :: forall eff
   . Fn4 Channel
    Queue
    ByteString
    Foreign
    (AMQPAction eff Boolean)

sendToQueue
  :: forall eff
   . Channel
  -> Queue
  -> ByteString
  -> (Options SendToQueueOptions)
  -> Aff (amqp :: AMQP | eff) Boolean
sendToQueue c q b o = makeAff $ (runFn4 _sendToQueue) c q b (options o)

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
