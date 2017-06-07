module Queue.AMQP.Client
  ( AMQP
  , Connection
  , Channel
  , Queue(..)
  , Exchange(..)
  , ExchangeType(..)

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
  ) where

import Prelude

import Control.Monad.Aff (Aff)
import Control.Monad.Eff (kind Effect)
import Control.Monad.Error.Class (class MonadError, catchError, throwError)
import Data.ByteString (ByteString)
import Data.Either (Either(..), either)
import Data.Foreign (Foreign, toForeign)
import Data.Generic (class Generic, gShow)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype)
import Data.Time.Duration (Milliseconds)


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
instance showExchange :: Show Exchange where show (Exchange s) = show s
derive instance newtypeExchange :: Newtype Exchange _

newtype ExchangeType = ExchangeType String
derive newtype instance eqExchangeType :: Eq ExchangeType
derive newtype instance ordExchangeType :: Ord ExchangeType
derive instance newtypeExchangeType :: Newtype ExchangeType _


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

instance showAssertExchangeResponse :: Show AssertExchangeResponseData where
  show (AssertExchangeResponse x) = "exchange: " <> (show x.exchange)

foreign import assertExchange
  :: forall eff
   . Channel
  -> Exchange
  -> ExchangeType
  -> AssertExchangeOptions
  -> Aff (amqp :: AMQP | eff) AssertExchangeResponse

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
foreign import sendToQueue
  :: forall eff
   . Channel
  -> Queue
  -> ByteString
  -> SendToQueueOptions
  -> Aff (amqp :: AMQP | eff) Boolean

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
