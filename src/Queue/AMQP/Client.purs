module Queue.AMQP.Client
  ( AMQP
  , Connection
  , Channel
  , Queue(..)

  , ConnectOptions
  , defaultConnectOptions
  , withConnection

  , withChannel

  , AssertQueueOptions
  , defaultAssertQueueOptions
  , AssertQueueResponse
  , assertQueue

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
