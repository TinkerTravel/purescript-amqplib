module Test.Main
  ( main
  ) where

import Control.Monad.Aff (Aff, launchAff)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Exception (EXCEPTION)
import Data.ByteString as ByteString
import Data.Maybe (Maybe(..))
import Node.Encoding (Encoding(UTF8))
import Prelude
import Queue.AMQP.Client (AMQP)
import Queue.AMQP.Client as AMQP

main :: forall eff. Eff (amqp :: AMQP, err :: EXCEPTION | eff) Unit
main = void $ launchAff main'

main' :: forall eff. Aff (amqp :: AMQP | eff) Unit
main' =
  AMQP.withConnection "amqp://localhost" AMQP.defaultConnectOptions \conn ->
    AMQP.withChannel conn \chan -> do
      let queue = AMQP.Queue "qu'est-ce que c'est"
      let message = ByteString.fromString "foobar" UTF8
      AMQP.assertQueue chan (Just queue) AMQP.defaultAssertQueueOptions
      AMQP.sendToQueue chan queue message AMQP.defaultSendToQueueOptions
      pure unit
