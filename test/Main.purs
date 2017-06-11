module Test.Main
  ( main
  ) where

import Prelude
import Queue.AMQP.Types

import Control.Monad.Aff (Aff, delay, runAff)
import Control.Monad.Aff.AVar (AVAR, AVar, makeVar', modifyVar, peekVar)
import Control.Monad.Aff.Console (CONSOLE)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (error)
import Control.Monad.Error.Class (throwError)
import Data.ByteString as ByteString
import Data.Foreign (toForeign)
import Data.Maybe (Maybe(..))
import Data.Options ((:=))
import Data.Time.Duration (Milliseconds(..))
import Node.Encoding (Encoding(UTF8))
import Queue.AMQP.AssertExchangeOptions (defaultAssertExchangeOptions)
import Queue.AMQP.AssertQueueOptions (defaultAssertQueueOptions, exclusive)
import Queue.AMQP.Client (AMQP, Channel)
import Queue.AMQP.Client as AMQP
import Queue.AMQP.PublishOptions (defaultPublishOptions)
import Queue.AMQP.SendToQueueOptions (defaultSendToQueueOptions)
import Test.Spec (describe, it)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (RunnerEffects, Config, run')

config :: Config
config = {
  slow: 75,
  timeout: Just 20000
}

assert ∷ forall eff. Boolean → Aff eff Unit
assert a = unless a (throwError (error  "Assertion failed"))


-- main :: forall eff. Eff (amqp :: AMQP, exception :: EXCEPTION | eff) Unit
main :: Eff (RunnerEffects ( amqp :: AMQP )) Unit
main = run' config  [consoleReporter] do -- void $ launchAff main'
  describe "amqp" do
    describe "work with queues" do
      it "sendToQueue" sendToQueueTest
    describe "work with topics" do
      it "sendToTopic" sendToTopicTest

sendToQueueTest :: forall e. Aff ( amqp :: AMQP | e) Unit
sendToQueueTest =
  AMQP.withConnection "amqp://localhost" AMQP.defaultConnectOptions \conn ->
    AMQP.withChannel conn \chan -> do
      let queue = Queue "qu'est-ce que c'est"
          message = ByteString.fromString "foobar" UTF8
      _ <- AMQP.assertQueue chan (Just queue) (defaultAssertQueueOptions <> exclusive := true)
      _ <- AMQP.sendToQueue chan queue message defaultSendToQueueOptions
      pure unit

sendToTopicTest :: forall e. Aff ( console :: CONSOLE, amqp :: AMQP, avar :: AVAR | e) Unit
sendToTopicTest =
  AMQP.withConnection "amqp://localhost" AMQP.defaultConnectOptions \conn ->
    AMQP.withChannel conn \chan -> do
      counter <- makeVar' 0 

      let exchange = Exchange "exchangeOne"
          exchangeType = ExchangeType "topic"
      exchangeResp <- AMQP.assertExchange chan exchange exchangeType defaultAssertExchangeOptions

      let routingKey = RouteKey "key"
          message = ByteString.fromString "foobar" UTF8

      let queue = Queue "plop"

      _ <- AMQP.assertQueue chan (Just queue) defaultAssertQueueOptions

      let pattern = Pattern "key"
          args = toForeign {}

      _ <- AMQP.bindQueue chan queue exchange pattern args

      _ <- AMQP.publish chan exchange routingKey message defaultPublishOptions

      _ <- AMQP.consume chan queue (func chan counter) Nothing -- Nothing

      _ <- AMQP.publish chan exchange routingKey message (defaultPublishOptions)

      delay (Milliseconds 1000.0) -- wait a bit
      value <- peekVar counter
      assert (value == 2)
      pure unit
    where
      func :: forall eCb . Channel -> AVar Int -> Maybe Message -> Eff (amqp :: AMQP, avar :: AVAR | eCb) Unit
      func chan counter (Just msg) = do
        _ <- runAff (const $ pure unit) (const $ pure unit) do
          _ <- AMQP.ack chan msg
          modifyVar (add 1) counter
        pure unit
      func chan counter Nothing = pure unit
        
        
