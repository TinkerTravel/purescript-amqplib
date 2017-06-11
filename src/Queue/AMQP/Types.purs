module Queue.AMQP.Types where

import Data.Bounded (class Ord)
import Data.ByteString (ByteString)
import Data.Eq (class Eq)
import Data.Foreign (Foreign)
import Data.Newtype (class Newtype)

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
