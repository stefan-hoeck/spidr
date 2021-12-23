{--
Copyright 2021 Joel Berkeley

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
||| This module contains common library types.
module Types

import public Data.Nat
import public Data.Vect

||| Describes the shape of a `Tensor`. For example, a `Tensor` of `Double`s with contents
||| `[[0, 1, 2], [3, 4, 5]]` has two elements in its outer-most axis, and each of those elements
||| has three `Double`s in it, so this has shape [2, 3]. A `Tensor` can have axes of zero length,
||| though the shape cannot be unambiguously inferred by visualising it. For example, `[[], []]`
||| can have shape [2, 0], [2, 0, 5] or etc. A scalar `Tensor` has shape `[]`.
|||
||| The rank is the number of elements in the shape, or equivalently the number of axes.
public export 0
Shape : {0 rank: Nat} -> Type
Shape = Vect rank Nat

||| An `Array shape` is either:
||| 
||| * a single value of an implicitly inferred type `dtype` (for `shape` `[]`), or
||| * an arbitrarily nested array of `Vect`s of such values (for any other `shape`)
|||
||| @shape The shape of this array.
public export 0
Array : {0 dtype : Type} -> (0 shape : Shape) -> Type
Array {dtype} [] = dtype
Array {dtype} (d :: ds) = Vect d (Array ds {dtype=dtype})