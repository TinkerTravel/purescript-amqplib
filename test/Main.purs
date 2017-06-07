module Test.Main
  ( main
  ) where

import Prelude

import Control.Monad.Aff (Aff, attempt)
import Control.Monad.Aff.Console (CONSOLE, log)
import Control.Monad.Eff (Eff)
import Data.ByteString as ByteString
import Data.Foreign (toForeign)
import Data.Maybe (Maybe(..))
import Debug.Trace (traceAnyA)
import Node.Encoding (Encoding(UTF8))
import Queue.AMQP.Client (AMQP, Pattern(..), assertQueue, bindQueue, defaultAssertExchangeOptions, defaultAssertQueueOptions, defaultPublishOptions, publish)
import Queue.AMQP.Client as AMQP
import Test.Spec (describe, it)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (RunnerEffects, Config, run')

config :: Config
config = {
  slow: 75,
  timeout: Just 20000
}

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
      let queue = AMQP.Queue "qu'est-ce que c'est"
          message = ByteString.fromString "foobar" UTF8
      _ <- AMQP.assertQueue chan (Just queue) AMQP.defaultAssertQueueOptions { exclusive = true }
      _ <- AMQP.sendToQueue chan queue message AMQP.defaultSendToQueueOptions
      pure unit

sendToTopicTest :: forall e. Aff ( console :: CONSOLE, amqp :: AMQP | e) Unit
sendToTopicTest =
  AMQP.withConnection "amqp://localhost" AMQP.defaultConnectOptions \conn ->
    AMQP.withChannel conn \chan -> do

      let exchange = AMQP.Exchange "exchangeOne"
          exchangeType = AMQP.ExchangeType "topic"
      exchangeResp <- AMQP.assertExchange chan exchange exchangeType (defaultAssertExchangeOptions)

      let routingKey = AMQP.RouteKey "key"
          message = ByteString.fromString "foobar" UTF8
      publishResp <-  AMQP.publish chan exchange routingKey message (defaultPublishOptions)

      let queue = AMQP.Queue "plop"

      _ <- AMQP.assertQueue chan (Just queue) defaultAssertQueueOptions

      let pattern = AMQP.Pattern "hop"
          args = toForeign {}

      _ <- AMQP.bindQueue chan queue exchange pattern args
      
      pure unit

