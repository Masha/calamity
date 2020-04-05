# Calamity

A discord library for haskell

# Example

``` haskell
import           Calamity.Client
import           Calamity.HTTP
import           Calamity.Types.General

import           Control.Concurrent.STM.TVar

import           Data.Default
import           Data.Text.Strict.Lens

import qualified Polysemy               as P
import qualified Polysemy.AtomicState   as P
import qualified Polysemy.Fail          as P
import qualified Polysemy.Embed         as P


data Counter m a where
  GetCounter :: Counter m Int

P.makeSem ''Counter

runCounterAtomic :: P.Member (P.Embed IO) r => P.Sem (Counter ': r) () -> P.Sem r ()
runCounterAtomic m = do
  var <- P.embed $ newTVarIO (0 :: Int)
  P.runAtomicStateTVar var $ P.reinterpret (\case GetCounter -> P.atomicState (\v -> (v + 1, v))) m

handleErrorByLogging m = do
  r <- P.runFail m
  case r of
    Left e ->
      error (e ^. packed)
    _ -> pure ()

main :: IO ()
main = do
  P.runFinal . P.embedToFinal . runCounterAtomic $ runBotIO (BotToken "") $ do
    react @"messagecreate" $ \msg state -> handleErrorByLogging $ do
      when (msg ^. #content == "!count") $ do
        val <- getCounter
        void . invokeRequest $ CreateMessage (msg ^. #channelID) ("The value is: " <> show val)
      when (msg ^. #content == "!say hi") $ do
        Right msg' <- invokeRequest $ CreateMessage (msg ^. #channelID) "heya"
        P.embed $ threadDelay 1000
        void . invokeRequest $ EditMessage (msg ^. #channelID) msg' (Just "lol") Nothing
```
