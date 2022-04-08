{--
Copyright 2022 Joel Berkeley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--}
module Compiler.XLA

import Data.Hashable
import Control.Monad.State
import Data.SortedMap

import Compiler.Graph
import Compiler.TensorFlow.Compiler.XLA.Client.XlaBuilder
import Compiler.TensorFlow.Compiler.XLA.Client.XlaComputation
import Compiler.TensorFlow.Compiler.XLA.ShapeUtil
import Compiler.TensorFlow.Compiler.XLA.XlaData
import Types

public export
data XlaBuilder : Type where
  MkXlaBuilder : GCAnyPtr -> SortedMap Bits64 GCAnyPtr -> XlaBuilder

-- note, the type of thing pointed to by the GCAnyPtr can be anything, and must be inferred from the
-- context.
public export
ComputationComponent : Type
ComputationComponent = StateT XlaBuilder IO GCAnyPtr

cacheInsert : XlaBuilder -> Bits64 -> GCAnyPtr -> XlaBuilder
cacheInsert (MkXlaBuilder ptr cache) k v = MkXlaBuilder ptr (insert k v cache)

cacheLookup : XlaBuilder -> Bits64 -> Maybe GCAnyPtr
cacheLookup (MkXlaBuilder _ cache) k = lookup k cache

export
cached : Graph -> ComputationComponent -> ComputationComponent
cached graph xs = let graphHash = assert_total $ hash graph in do
  builder <- get
  case cacheLookup builder graphHash of
    Just op_ptr => pure op_ptr
    Nothing => do
      op_ptr <- xs
      builder <- get
      put (cacheInsert builder graphHash op_ptr)
      pure op_ptr

mkXlaBuilder : String -> IO XlaBuilder
mkXlaBuilder computation_name = do
  ptr <- primIO (prim__mkXlaBuilder computation_name)
  ptr <- onCollectAny ptr XlaBuilder.delete
  pure (MkXlaBuilder ptr empty)

export
build : String -> ComputationComponent -> IO GCAnyPtr
build computation_name x = do
  builder <- mkXlaBuilder computation_name
  (MkXlaBuilder ptr _) <- execStateT builder x
  onCollectAny (prim__build ptr) XlaComputation.delete

export
buildWithSubBuilder :
  String -> List ComputationComponent -> ComputationComponent -> ComputationComponent
buildWithSubBuilder computation_name args res = do
  MkXlaBuilder ptr _ <- get
  sub_ptr <- primIO (prim__createSubBuilder ptr computation_name)
  sub_ptr <- onCollectAny sub_ptr XlaBuilder.delete
  let sub_builder = MkXlaBuilder sub_ptr empty
      all_ops = sequence_ (args ++ [res])
  MkXlaBuilder sub_ptr _ <- liftIO $ execStateT sub_builder all_ops
  let computation = prim__build sub_ptr
  onCollectAny computation XlaComputation.delete

export
prim__opToString : ComputationComponent -> IO String
prim__opToString xs = do
  builder <- mkXlaBuilder "toString"
  (MkXlaBuilder ptr _, op) <- runStateT builder xs
  pure (XlaBuilder.prim__opToString ptr op)

export
prim__constantLiteral : GCAnyPtr -> Graph -> ComputationComponent
prim__constantLiteral literal graph = do
  MkXlaBuilder ptr _ <- get
  op <- primIO $ prim__constantLiteral ptr literal
  onCollectAny op XlaOp.delete

export
prim__parameter : Primitive dtype => Int -> Shape -> String -> ComputationComponent
prim__parameter position shape name = do
  (MkXlaBuilder ptr _) <- get
  xla_shape <- mkShape {dtype} shape
  op <- primIO $ prim__parameter ptr position xla_shape name
  onCollectAny op XlaOp.delete