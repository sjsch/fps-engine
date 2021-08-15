{-# LANGUAGE FlexibleContexts #-}

module Util.Pipes (zipP, runGetPipe) where

import Control.Monad.State
import qualified Data.ByteString as B
import Data.Serialize (Get, runGetState)
import Pipes
import Pipes.Lift

zipP :: (Traversable t, Monad m) => t (Producer a m r) -> Producer (t a) m r
zipP ps = do
  rs <- fmap sequence (traverse (lift . next) ps)
  case rs of
    Left r -> pure r
    Right xs -> do
      yield (fmap fst xs)
      zipP (fmap snd xs)

runGetPipe :: Monad m => Proxy a' a b' b Get r -> B.ByteString -> Proxy a' a b' b m r
runGetPipe p = evalStateT (distribute (hoist f p))
  where
    f g = do
      s <- get
      let Right (x, s') = runGetState g s 0
      put s'
      pure x
