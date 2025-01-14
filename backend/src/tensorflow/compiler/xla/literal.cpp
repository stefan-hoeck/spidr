/*
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
*/
#include "tensorflow/compiler/xla/literal.h"

#include "literal.h"
#include "shape.h"

extern "C" {
    Literal* Literal_new(Shape& shape) {
        xla::Shape& shape_ = reinterpret_cast<xla::Shape&>(shape);
        xla::Literal* lit = new xla::Literal(shape_, true);
        return reinterpret_cast<Literal*>(lit);
    }

    void Literal_delete(Literal* lit) {
        delete reinterpret_cast<xla::Literal*>(lit);
    }
}

template <typename NativeT>
NativeT Literal_Get(Literal& lit, int* indices) {
    xla::Literal& lit_ = reinterpret_cast<xla::Literal&>(lit);
    int64_t rank = lit_.shape().rank();
    int64_t multi_index[rank];
    std::copy(indices, indices + rank, multi_index);
    return lit_.Get<NativeT>(absl::Span<const int64_t>(multi_index, rank));
};

template <typename NativeT>
void Literal_Set(Literal& lit, int* indices, NativeT value) {
    xla::Literal& lit_ = reinterpret_cast<xla::Literal&>(lit);
    int64_t rank = lit_.shape().rank();
    int64_t multi_index[rank];
    std::copy(indices, indices + rank, multi_index);
    lit_.Set<NativeT>(absl::Span<const int64_t>(multi_index, rank), value);
};

extern "C" {
    int Literal_Get_bool(Literal& lit, int* indices) {
        return (int) Literal_Get<bool>(lit, indices);
    }

    int Literal_Get_int32_t(Literal& lit, int* indices) {
        return Literal_Get<int32_t>(lit, indices);
    }

    int Literal_Get_uint32_t(Literal& lit, int* indices) {
        return (int) Literal_Get<uint32_t>(lit, indices);
    }

    int Literal_Get_uint64_t(Literal& lit, int* indices) {
        return (int) Literal_Get<uint64_t>(lit, indices);
    }

    double Literal_Get_double(Literal& lit, int* indices) {
        return Literal_Get<double>(lit, indices);
    }

    void Literal_Set_bool(Literal& lit, int* indices, int value) {
        Literal_Set<bool>(lit, indices, (bool) value);
    }

    void Literal_Set_int32_t(Literal& lit, int* indices, int value) {
        Literal_Set<int32_t>(lit, indices, value);
    }

    void Literal_Set_uint32_t(Literal& lit, int* indices, int value) {
        Literal_Set<uint32_t>(lit, indices, (uint32_t) value);
    }

    void Literal_Set_uint64_t(Literal& lit, int* indices, int value) {
        Literal_Set<uint64_t>(lit, indices, (uint64_t) value);
    }

    void Literal_Set_double(Literal& lit, int* indices, double value) {
        Literal_Set<double>(lit, indices, value);
    }
}
