module Queue.AMQP.PublishOptions where
  

  -- Used by RabbitMQ and sent on to consumers:
import Data.Foreign (Foreign)
import Data.Monoid (mempty)
import Data.Options (Option, Options, opt)
  

  -- Used by RabbitMQ and sent on to consumers:
foreign import data PublishOptions :: Type

expiration :: Option PublishOptions String
expiration = opt "expiration"    -- if supplied, the message will be discarded from a queue once it's been there longer than the given number of milliseconds. In the specification this is a string; numbers supplied here will be coerced to strings for transit.

userId :: Option PublishOptions String
userId = opt "userId"  -- If supplied, RabbitMQ will compare it to the username supplied when opening the connection, and reject messages for which it does not match.

cC :: Option PublishOptions (Array String)
cC = opt "CC" -- an array of routing keys as strings; messages will be routed to these routing keys in addition to that given as the routingKey parameter. This will override any value given for CC in the headers parameter. NB The property names CC and BCC are case-sensitive.

priority :: Option PublishOptions Int
priority = opt "priority" -- (positive integer): a priority for the message; ignored by versions of RabbitMQ older than 3.5.0, or if the queue is not a priority queue (see maxPriority above).

persistent :: Option PublishOptions Boolean
persistent = opt "persistent"  -- If truthy, the message will survive broker restarts provided it's in a queue that also survives restarts. Corresponds to, and overrides, the property deliveryMode.

-- Used by RabbitMQ but not sent on to consumers:
mandatory :: Option PublishOptions Boolean
mandatory = opt "mandatory" -- if true, the message will be returned if it is not routed to a queue (i.e., if there are no bindings that match its routing key).

bCC :: Option PublishOptions (Array String)
bCC = opt "BCC" -- like CC, except that the value will not be sent in the message headers to consumers.

-- Ignored by RabbitMQ (but may be useful for applications):

contentType :: Option PublishOptions String
contentType = opt "contentType" -- a MIME type for the message content

contentEncoding :: Option PublishOptions String 
contentEncoding = opt "contentEncoding" --  a MIME encoding for the message content

headers :: Option PublishOptions Foreign
headers = opt "headers" -- (object): application specific headers to be carried along with the message content. The value as sent may be augmented by extension-specific fields if they are given in the parameters, for example, 'CC', since these are encoded as message headers; the supplied value won't be mutated

correlationId :: Option PublishOptions String
correlationId = opt "correlationId" -- usually used to match replies to requests, or similar

replyTo :: Option PublishOptions String
replyTo = opt "replyTo" -- often used to name a queue to which the receiving application must send replies, in an RPC scenario (many libraries assume this pattern)

messageId :: Option PublishOptions String
messageId = opt "messageId" -- arbitrary application-specific identifier for the message

timestamp :: Option PublishOptions Number
timestamp = opt "timestamp" -- a timestamp for the message

type_ :: Option PublishOptions String
type_ = opt "type" -- an arbitrary application-specific type for the message

appId :: Option PublishOptions String
appId = opt "appId" -- an arbitrary identifier for the originating application


defaultPublishOptions :: Options PublishOptions
defaultPublishOptions = mempty


