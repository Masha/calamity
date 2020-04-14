-- | A message from a channel
module Calamity.Types.Model.Channel.Message
    ( Message(..)
    , UpdatedMessage(..)
    , MessageType(..) ) where

import           Calamity.Internal.AesonThings
import           Calamity.Internal.SnowflakeMap        ( SnowflakeMap )
import           Calamity.Types.Model.Channel
import           Calamity.Types.Model.Channel.Embed
import           Calamity.Types.Model.Channel.Reaction
import {-# SOURCE #-} Calamity.Types.Model.Guild.Guild
import           Calamity.Types.Model.Guild.Member
import           Calamity.Types.Model.Guild.Role
import {-# SOURCE #-} Calamity.Types.Model.User
import           Calamity.Types.Snowflake

import           Control.Monad

import           Data.Aeson
import qualified Data.Override                         as O
import           Data.Override.Aeson                   ()
import           Data.Scientific
import           Data.Time
import           Data.Vector                           ( Vector )
import qualified Data.Vector.Unboxed                   as UV

-- NOTE: make sure we fill in the guildID field when retrieving from REST
data Message = Message
  { id              :: Snowflake Message
  , channelID       :: Snowflake Channel
  , guildID         :: Maybe (Snowflake Guild)
  , author          :: Snowflake User
  , content         :: ShortText
  , timestamp       :: UTCTime
  , editedTimestamp :: Maybe UTCTime
  , tts             :: Bool
  , mentionEveryone :: Bool
  , mentions        :: SnowflakeMap (Snowflake User)
  , mentionRoles    :: UV.Vector (Snowflake Role)
  , attachments     :: Vector Attachment
  , embeds          :: Vector Embed
  , reactions       :: Vector Reaction
  , nonce           :: Maybe (Snowflake Message)
  , pinned          :: Bool
  , webhookID       :: Maybe (Snowflake ())
  , type_           :: MessageType
  }
  deriving ( Eq, Show, Generic )
  deriving ( ToJSON ) via CalamityJSON Message
  deriving ( FromJSON ) via WithSpecialCases
      '["author" `ExtractField` "id",
        "reactions" `IfNoneThen` DefaultToEmptyArray]
      Message
  deriving ( HasID ) via HasIDField Message

data UpdatedMessage = UpdatedMessage
  { id              :: Snowflake UpdatedMessage
  , channelID       :: Snowflake Channel
  , content         :: Maybe ShortText
  , editedTimestamp :: Maybe UTCTime
  , tts             :: Maybe Bool
  , mentionEveryone :: Maybe Bool
  , mentions        :: Maybe (SnowflakeMap (Snowflake User))
  , mentionRoles    :: Maybe (UV.Vector (Snowflake Role))
  , attachments     :: Maybe (Vector Attachment)
  , embeds          :: Maybe (Vector Embed)
  , reactions       :: Maybe (Vector Reaction)
  , pinned          :: Maybe Bool
  }
  deriving ( Eq, Show, Generic )
  deriving ( FromJSON ) via CalamityJSON UpdatedMessage
  deriving ( HasID ) via HasIDFieldCoerce UpdatedMessage Message

-- Thanks sbrg (https://github.com/saevarb/haskord/blob/d1bb07bcc4f3dbc29f2dfd3351ff9f16fc100c07/haskord-lib/src/Haskord/Types/Common.hs#L264)
data MessageType
  = Default
  | RecipientAdd
  | RecipientRemove
  | Call
  | ChannelNameChange
  | ChannelIconChange
  | ChannelPinnedMessage
  | GuildMemberJoin
  deriving ( Eq, Show, Enum )

instance ToJSON MessageType where
  toJSON t = Number $ fromIntegral (fromEnum t)

instance FromJSON MessageType where
  parseJSON = withScientific "MessageType" $ \n -> case toBoundedInteger n of
    Just v  -> pure $ toEnum v
    Nothing -> fail $ "Invalid MessageType: " <> show n
