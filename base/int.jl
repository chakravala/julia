## integer arithmetic ##

const IntTypes = (Int8, UInt8, Int16, UInt16, Int32, UInt32,
                  Int64, UInt64, Int128, UInt128)

+(x::Int, y::Int) = box(Int,add_int(unbox(Int,x),unbox(Int,y)))
<(x::Int, y::Int) = slt_int(unbox(Int,x),unbox(Int,y))

for T in IntTypes
    @eval begin
        -(x::$T) = box($T,neg_int(unbox($T,x)))
        +(x::$T, y::$T) = box($T, add_int(unbox($T,x),unbox($T,y)))
        -(x::$T, y::$T) = box($T, sub_int(unbox($T,x),unbox($T,y)))
        *(x::$T, y::$T) = box($T, mul_int(unbox($T,x),unbox($T,y)))
    end
end

/(x::Integer, y::Integer) = float(x)/float(y)
inv(x::Integer) = float(one(x))/float(x)

isodd(n::Integer) = Bool(rem(n,2))
iseven(n::Integer) = !isodd(n)

signbit(x::Integer) = x < 0
signbit(x::Unsigned) = false

for T in (Int8,Int16,Int32,Int64,Int128)
    @eval flipsign(x::$T, y::$T) = box($T,flipsign_int(unbox($T,x),unbox($T,y)))
end

flipsign(x::Signed, y::Signed)  = flipsign(promote(x,y)...)
flipsign(x::Signed, y::Float32) = flipsign(x, reinterpret(Int32,y))
flipsign(x::Signed, y::Float64) = flipsign(x, reinterpret(Int64,y))
flipsign(x::Signed, y::Real)    = flipsign(x, -oftype(x,signbit(y)))

copysign(x::Signed, y::Signed)  = flipsign(x, x$y)
copysign(x::Signed, y::Float32) = copysign(x, reinterpret(Int32,y))
copysign(x::Signed, y::Float64) = copysign(x, reinterpret(Int64,y))
copysign(x::Signed, y::Real)    = copysign(x, -oftype(x,signbit(y)))

abs(x::Unsigned) = x
abs(x::Signed) = flipsign(x,x)

~(n::Integer) = -n-1

unsigned(x::Signed) = reinterpret(typeof(convert(Unsigned,zero(x))), x)
unsigned(x::Bool) = convert(Unsigned, x)
unsigned(x) = convert(Unsigned, x)
signed(x::Unsigned) = reinterpret(typeof(convert(Signed,zero(x))), x)
signed(x) = convert(Signed, x)

div(x::Signed, y::Unsigned) = flipsign(signed(div(unsigned(abs(x)),y)),x)
div(x::Unsigned, y::Signed) = unsigned(flipsign(signed(div(x,unsigned(abs(y)))),y))

rem(x::Signed, y::Unsigned) = flipsign(signed(rem(unsigned(abs(x)),y)),x)
rem(x::Unsigned, y::Signed) = rem(x,unsigned(abs(y)))

fld(x::Signed, y::Unsigned) = div(x,y)-(signbit(x)&(rem(x,y)!=0))
fld(x::Unsigned, y::Signed) = div(x,y)-(signbit(y)&(rem(x,y)!=0))

mod(x::Signed, y::Unsigned) = rem(y+unsigned(rem(x,y)),y)
mod(x::Unsigned, y::Signed) = rem(y+signed(rem(x,y)),y)

cld(x::Signed, y::Unsigned) = div(x,y)+(!signbit(x)&(rem(x,y)!=0))
cld(x::Unsigned, y::Signed) = div(x,y)+(!signbit(y)&(rem(x,y)!=0))

# Don't promote integers for div/rem/mod since there no danger of overflow,
# while there is a substantial performance penalty to 64-bit promotion.
typealias Signed64 Union(Int8,Int16,Int32,Int64)
typealias Unsigned64 Union(UInt8,UInt16,UInt32,UInt64)
typealias Integer64 Union(Signed64,Unsigned64)

div{T<:Signed64}  (x::T, y::T) = box(T,sdiv_int(unbox(T,x),unbox(T,y)))
div{T<:Unsigned64}(x::T, y::T) = box(T,udiv_int(unbox(T,x),unbox(T,y)))
rem{T<:Signed64}  (x::T, y::T) = box(T,srem_int(unbox(T,x),unbox(T,y)))
rem{T<:Unsigned64}(x::T, y::T) = box(T,urem_int(unbox(T,x),unbox(T,y)))
mod{T<:Signed64}  (x::T, y::T) = box(T,smod_int(unbox(T,x),unbox(T,y)))

mod{T<:Unsigned}(x::T, y::T) = rem(x,y)

fld{T<:Unsigned}(x::T, y::T) = div(x,y)
fld{T<:Integer }(x::T, y::T) = div(x,y)-(signbit(x$y)&(rem(x,y)!=0))

cld{T<:Unsigned}(x::T, y::T) = div(x,y)+(rem(x,y)!=0)
cld{T<:Integer }(x::T, y::T) = div(x,y)+(!signbit(x$y)&(rem(x,y)!=0))

## integer bitwise operations ##

for T in IntTypes
    @eval begin
        ~(x::$T) = box($T,not_int(unbox($T,x)))

        (&)(x::$T, y::$T) = box($T,and_int(unbox($T,x),unbox($T,y)))
        (|)(x::$T, y::$T) = box($T, or_int(unbox($T,x),unbox($T,y)))
        ($)(x::$T, y::$T) = box($T,xor_int(unbox($T,x),unbox($T,y)))

        <<(x::$T,  y::Int32) = box($T, shl_int(unbox($T,x),unbox(Int32,y)))
        >>>(x::$T, y::Int32) = box($T,lshr_int(unbox($T,x),unbox(Int32,y)))
    end
    if issubtype(T,Unsigned)
        @eval >>(x::$T, y::Int32) = box($T,lshr_int(unbox($T,x),unbox(Int32,y)))
    else
        @eval >>(x::$T, y::Int32) = box($T,ashr_int(unbox($T,x),unbox(Int32,y)))
    end
end

bswap(x::Int8)    = x
bswap(x::UInt8)   = x
bswap(x::Int16)   = box(Int16,bswap_int(unbox(Int16,x)))
bswap(x::UInt16)  = box(UInt16,bswap_int(unbox(UInt16,x)))
bswap(x::Int32)   = box(Int32,bswap_int(unbox(Int32,x)))
bswap(x::UInt32)  = box(UInt32,bswap_int(unbox(UInt32,x)))
bswap(x::Int64)   = box(Int64,bswap_int(unbox(Int64,x)))
bswap(x::UInt64)  = box(UInt64,bswap_int(unbox(UInt64,x)))
bswap(x::Int128)  = box(Int128,bswap_int(unbox(Int128,x)))
bswap(x::UInt128) = box(UInt128,bswap_int(unbox(UInt128,x)))

for T in IntTypes
    @eval begin
        count_ones(x::$T)     = Int(box($T,ctpop_int(unbox($T,x))))
        leading_zeros(x::$T)  = Int(box($T,ctlz_int(unbox($T,x))))
        trailing_zeros(x::$T) = Int(box($T,cttz_int(unbox($T,x))))
    end
end
count_zeros  (x::Integer) = count_ones(~x)
leading_ones (x::Integer) = leading_zeros(~x)
trailing_ones(x::Integer) = trailing_zeros(~x)

## integer comparisons ##

for T in IntTypes
    if issubtype(T,Signed)
        @eval <( x::$T, y::$T) = slt_int(unbox($T,x),unbox($T,y))
        @eval <=(x::$T, y::$T) = sle_int(unbox($T,x),unbox($T,y))
    else
        @eval <( x::$T, y::$T) = ult_int(unbox($T,x),unbox($T,y))
        @eval <=(x::$T, y::$T) = ule_int(unbox($T,x),unbox($T,y))
    end
end

==(x::Signed,   y::Unsigned) = (x >= 0) & (unsigned(x) == y)
==(x::Unsigned, y::Signed  ) = (y >= 0) & (x == unsigned(y))
< (x::Signed,   y::Unsigned) = (x <  0) | (unsigned(x) <  y)
< (x::Unsigned, y::Signed  ) = (y >  0) & (x <  unsigned(y))
<=(x::Signed,   y::Unsigned) = (x <= 0) | (unsigned(x) <= y)
<=(x::Unsigned, y::Signed  ) = (y >= 0) & (x <= unsigned(y))

## integer conversions ##

for to in tuple(IntTypes...,Char), from in tuple(IntTypes...,Char,Bool)
    if !(to === from)
        if to.size < from.size
            if issubtype(to, Signed)
                if issubtype(from, Unsigned)
                    @eval convert(::Type{$to}, x::($from)) = box($to,checked_trunc_sint($to,check_top_bit(unbox($from,x))))
                else
                    @eval convert(::Type{$to}, x::($from)) = box($to,checked_trunc_sint($to,unbox($from,x)))
                end
            else
                @eval convert(::Type{$to}, x::($from)) = box($to,checked_trunc_uint($to,unbox($from,x)))
            end
            @eval rem(x::($from), ::Type{$to}) = box($to,trunc_int($to,unbox($from,x)))
        elseif from.size < to.size || from === Bool
            if issubtype(from, Signed)
                if issubtype(to, Unsigned)
                    @eval convert(::Type{$to}, x::($from)) = box($to,sext_int($to,check_top_bit(unbox($from,x))))
                else
                    @eval convert(::Type{$to}, x::($from)) = box($to,sext_int($to,unbox($from,x)))
                end
                @eval rem(x::($from), ::Type{$to}) = box($to,sext_int($to,unbox($from,x)))
            else
                @eval convert(::Type{$to}, x::($from)) = box($to,zext_int($to,unbox($from,x)))
                @eval rem(x::($from), ::Type{$to}) = convert($to,x)
            end
        else
            if !(issubtype(from,Signed) === issubtype(to,Signed))
                # raise InexactError if x's top bit is set
                @eval convert(::Type{$to}, x::($from)) = box($to,check_top_bit(unbox($from,x)))
            else
                @eval convert(::Type{$to}, x::($from)) = box($to,unbox($from,x))
            end
            @eval rem(x::($from), ::Type{$to}) = box($to,unbox($from,x))
        end
    end
end

rem{T<:Integer}(x::T, ::Type{T}) = x
rem(x::Integer, ::Type{Bool}) = ((x&1)!=0)
mod{T<:Integer}(x::Integer, ::Type{T}) = rem(x, T)

for to in (Int8, Int16, Int32, Int64)
    @eval begin
        convert(::Type{$to}, x::Float32) = box($to,checked_fptosi($to,unbox(Float32,x)))
        convert(::Type{$to}, x::Float64) = box($to,checked_fptosi($to,unbox(Float64,x)))
    end
end

for to in (UInt8, UInt16, UInt32, UInt64)
    @eval begin
        convert(::Type{$to}, x::Float32) = box($to,checked_fptoui($to,unbox(Float32,x)))
        convert(::Type{$to}, x::Float64) = box($to,checked_fptoui($to,unbox(Float64,x)))
    end
end

for Ti in (Int128,UInt128)
    for Tf in (Float32,Float64)
        @eval function convert(::Type{$Ti},x::$Tf)
            isinteger(x) || throw(InexactError())
            trunc($Ti,x)
        end
    end
end

convert(::Type{Signed}, x::UInt8  ) = convert(Int8,x)
convert(::Type{Signed}, x::UInt16 ) = convert(Int16,x)
convert(::Type{Signed}, x::UInt32 ) = convert(Int32,x)
convert(::Type{Signed}, x::UInt64 ) = convert(Int64,x)
convert(::Type{Signed}, x::UInt128) = convert(Int128,x)
convert(::Type{Signed}, x::Float32) = convert(Int,x)
convert(::Type{Signed}, x::Float64) = convert(Int,x)
convert(::Type{Signed}, x::Char)    = convert(Int,x)
convert(::Type{Signed}, x::Bool)    = convert(Int,x)

convert(::Type{Unsigned}, x::Int8   ) = convert(UInt8,x)
convert(::Type{Unsigned}, x::Int16  ) = convert(UInt16,x)
convert(::Type{Unsigned}, x::Int32  ) = convert(UInt32,x)
convert(::Type{Unsigned}, x::Int64  ) = convert(UInt64,x)
convert(::Type{Unsigned}, x::Int128 ) = convert(UInt128,x)
convert(::Type{Unsigned}, x::Float32) = convert(UInt,x)
convert(::Type{Unsigned}, x::Float64) = convert(UInt,x)
convert(::Type{Unsigned}, x::Char)    = convert(UInt,x)
convert(::Type{Unsigned}, x::Bool)    = convert(UInt,x)

convert(::Type{Integer}, x::Integer) = x
convert(::Type{Integer}, x::Union(Real,Char)) = convert(Signed,x)

round(x::Integer) = x
trunc(x::Integer) = x
floor(x::Integer) = x
 ceil(x::Integer) = x

round{T<:Integer}(::Type{T},x::Integer) = convert(T,x)
trunc{T<:Integer}(::Type{T},x::Integer) = convert(T,x)
floor{T<:Integer}(::Type{T},x::Integer) = convert(T,x)
 ceil{T<:Integer}(::Type{T},x::Integer) = convert(T,x)

## integer construction ##

macro int128_str(x)
    if isa(x,AbstractString)
        parseint(Int128,x)
    else
        Int128(x)
    end
end

macro uint128_str(x)
    if isa(x,AbstractString)
        parseint(UInt128,x)
    else
        UInt128(x)
    end
end

macro bigint_str(str)
    BigInt(str)
end

## system word size ##

const WORD_SIZE = Int(Int.size)*8

## integer promotions ##

promote_rule(::Type{Int16},  ::Type{Int8} ) = Int16
promote_rule(::Type{Int32},  ::Type{Int8} ) = Int32
promote_rule(::Type{Int32},  ::Type{Int16}) = Int32
promote_rule(::Type{Int64},  ::Type{Int8} ) = Int64
promote_rule(::Type{Int64},  ::Type{Int16}) = Int64
promote_rule(::Type{Int64},  ::Type{Int32}) = Int64
promote_rule(::Type{Int128}, ::Type{Int8} ) = Int128
promote_rule(::Type{Int128}, ::Type{Int16}) = Int128
promote_rule(::Type{Int128}, ::Type{Int32}) = Int128
promote_rule(::Type{Int128}, ::Type{Int64}) = Int128

promote_rule(::Type{UInt16},  ::Type{UInt8} ) = UInt16
promote_rule(::Type{UInt32},  ::Type{UInt8} ) = UInt32
promote_rule(::Type{UInt32},  ::Type{UInt16}) = UInt32
promote_rule(::Type{UInt64},  ::Type{UInt8} ) = UInt64
promote_rule(::Type{UInt64},  ::Type{UInt16}) = UInt64
promote_rule(::Type{UInt64},  ::Type{UInt32}) = UInt64
promote_rule(::Type{UInt128}, ::Type{UInt8} ) = UInt128
promote_rule(::Type{UInt128}, ::Type{UInt16}) = UInt128
promote_rule(::Type{UInt128}, ::Type{UInt32}) = UInt128
promote_rule(::Type{UInt128}, ::Type{UInt64}) = UInt128

promote_rule(::Type{UInt8}, ::Type{Int8}  ) = Int
promote_rule(::Type{UInt8}, ::Type{Int16} ) = Int
promote_rule(::Type{UInt8}, ::Type{Int32} ) = Int
promote_rule(::Type{UInt8}, ::Type{Int64} ) = Int64
promote_rule(::Type{UInt8}, ::Type{Int128}) = Int128

promote_rule(::Type{UInt16}, ::Type{Int8}  ) = Int
promote_rule(::Type{UInt16}, ::Type{Int16} ) = Int
promote_rule(::Type{UInt16}, ::Type{Int32} ) = Int
promote_rule(::Type{UInt16}, ::Type{Int64} ) = Int64
promote_rule(::Type{UInt16}, ::Type{Int128}) = Int128

if WORD_SIZE == 64
    promote_rule(::Type{UInt32}, ::Type{Int8} ) = Int
    promote_rule(::Type{UInt32}, ::Type{Int16}) = Int
    promote_rule(::Type{UInt32}, ::Type{Int32}) = Int
else
    promote_rule(::Type{UInt32}, ::Type{Int8} ) = UInt
    promote_rule(::Type{UInt32}, ::Type{Int16}) = UInt
    promote_rule(::Type{UInt32}, ::Type{Int32}) = UInt
end
promote_rule(::Type{UInt32}, ::Type{Int64} ) = Int64
promote_rule(::Type{UInt32}, ::Type{Int128}) = Int128

promote_rule(::Type{UInt64}, ::Type{Int8}  ) = UInt64
promote_rule(::Type{UInt64}, ::Type{Int16} ) = UInt64
promote_rule(::Type{UInt64}, ::Type{Int32} ) = UInt64
promote_rule(::Type{UInt64}, ::Type{Int64} ) = UInt64
promote_rule(::Type{UInt64}, ::Type{Int128}) = Int128

promote_rule(::Type{UInt128}, ::Type{Int8}  ) = UInt128
promote_rule(::Type{UInt128}, ::Type{Int16} ) = UInt128
promote_rule(::Type{UInt128}, ::Type{Int32} ) = UInt128
promote_rule(::Type{UInt128}, ::Type{Int64} ) = UInt128
promote_rule(::Type{UInt128}, ::Type{Int128}) = UInt128

## traits ##

typemin(::Type{Int8  }) = Int8(-128)
typemax(::Type{Int8  }) = Int8(127)
typemin(::Type{UInt8 }) = UInt8(0)
typemax(::Type{UInt8 }) = UInt8(255)
typemin(::Type{Int16 }) = Int16(-32768)
typemax(::Type{Int16 }) = Int16(32767)
typemin(::Type{UInt16}) = UInt16(0)
typemax(::Type{UInt16}) = UInt16(65535)
typemin(::Type{Int32 }) = Int32(-2147483648)
typemax(::Type{Int32 }) = Int32(2147483647)
typemin(::Type{UInt32}) = UInt32(0)
typemax(::Type{UInt32}) = UInt32(4294967295)
typemin(::Type{Int64 }) = -9223372036854775808
typemax(::Type{Int64 }) = 9223372036854775807
typemin(::Type{UInt64}) = UInt64(0)
typemax(::Type{UInt64}) = 0xffffffffffffffff
@eval typemin(::Type{UInt128}) = $(UInt128(0))
@eval typemax(::Type{UInt128}) = $(box(UInt128,unbox(Int128,convert(Int128,-1))))
@eval typemin(::Type{Int128} ) = $(convert(Int128,1)<<Int32(127))
@eval typemax(::Type{Int128} ) = $(box(Int128,unbox(UInt128,typemax(UInt128)>>Int32(1))))

widen(::Type{Int8}) = Int
widen(::Type{Int16}) = Int
widen(::Type{Int32}) = Int64
widen(::Type{Int64}) = Int128
widen(::Type{UInt8}) = UInt
widen(::Type{UInt16}) = UInt
widen(::Type{UInt32}) = UInt64
widen(::Type{UInt64}) = UInt128

# a few special cases,
# Int64*UInt64 => Int128
# |x|<=2^(k-1), |y|<=2^k-1   =>   |x*y|<=2^(2k-1)-1
widemul(x::Signed,y::Unsigned) = widen(x)*signed(widen(y))
widemul(x::Unsigned,y::Signed) = signed(widen(x))*widen(y)
# multplication by Bool doesn't require widening
widemul(x::Bool,y::Bool) = x*y
widemul(x::Bool,y::Number) = x*y
widemul(x::Number,y::Bool) = x*y


## wide multiplication, Int128 multiply and divide ##

if WORD_SIZE==32
    function widemul(u::Int64, v::Int64)
        local u0::UInt64, v0::UInt64, w0::UInt64
        local u1::Int64, v1::Int64, w1::UInt64, w2::Int64, t::UInt64

        u0 = u&0xffffffff; u1 = u>>32
        v0 = v&0xffffffff; v1 = v>>32
        w0 = u0*v0
        t = reinterpret(UInt64,u1)*v0 + (w0>>>32)
        w2 = reinterpret(Int64,t) >> 32
        w1 = u0*reinterpret(UInt64,v1) + (t&0xffffffff)
        hi = u1*v1 + w2 + (reinterpret(Int64,w1) >> 32)
        lo = w0&0xffffffff + (w1 << 32)
        Int128(hi)<<64 + Int128(lo)
    end

    function widemul(u::UInt64, v::UInt64)
        local u0::UInt64, v0::UInt64, w0::UInt64
        local u1::UInt64, v1::UInt64, w1::UInt64, w2::UInt64, t::UInt64

        u0 = u&0xffffffff; u1 = u>>>32
        v0 = v&0xffffffff; v1 = v>>>32
        w0 = u0*v0
        t = u1*v0 + (w0>>>32)
        w2 = t>>>32
        w1 = u0*v1 + (t&0xffffffff)
        hi = u1*v1 + w2 + (w1 >>> 32)
        lo = w0&0xffffffff + (w1 << 32)
        UInt128(hi)<<64 + UInt128(lo)
    end

    function *(u::Int128, v::Int128)
        u0 = u % UInt64; u1 = Int64(u>>64)
        v0 = v % UInt64; v1 = Int64(v>>64)
        lolo = widemul(u0, v0)
        lohi = widemul(reinterpret(Int64,u0), v1)
        hilo = widemul(u1, reinterpret(Int64,v0))
        t = reinterpret(UInt128,hilo) + (lolo>>>64)
        w1 = reinterpret(UInt128,lohi) + (t&0xffffffffffffffff)
        Int128(lolo&0xffffffffffffffff) + reinterpret(Int128,w1)<<64
    end

    function *(u::UInt128, v::UInt128)
        u0 = u % UInt64; u1 = UInt64(u>>>64)
        v0 = v % UInt64; v1 = UInt64(v>>>64)
        lolo = widemul(u0, v0)
        lohi = widemul(u0, v1)
        hilo = widemul(u1, v0)
        t = hilo + (lolo>>>64)
        w1 = lohi + (t&0xffffffffffffffff)
        (lolo&0xffffffffffffffff) + UInt128(w1)<<64
    end

    div(x::Int128, y::Int128) = Int128(div(BigInt(x),BigInt(y)))
    div(x::UInt128, y::UInt128) = UInt128(div(BigInt(x),BigInt(y)))

    rem(x::Int128, y::Int128) = Int128(rem(BigInt(x),BigInt(y)))
    rem(x::UInt128, y::UInt128) = UInt128(rem(BigInt(x),BigInt(y)))

    mod(x::Int128, y::Int128) = Int128(mod(BigInt(x),BigInt(y)))

    << (x::Int128,  y::Int32) = y == 0 ? x : box(Int128,shl_int(unbox(Int128,x),unbox(Int32,y)))
    << (x::UInt128, y::Int32) = y == 0 ? x : box(UInt128,shl_int(unbox(UInt128,x),unbox(Int32,y)))
    >> (x::Int128,  y::Int32) = y == 0 ? x : box(Int128,ashr_int(unbox(Int128,x),unbox(Int32,y)))
    >> (x::UInt128, y::Int32) = y == 0 ? x : box(UInt128,lshr_int(unbox(UInt128,x),unbox(Int32,y)))
    >>>(x::Int128,  y::Int32) = y == 0 ? x : box(Int128,lshr_int(unbox(Int128,x),unbox(Int32,y)))
    >>>(x::UInt128, y::Int32) = y == 0 ? x : box(UInt128,lshr_int(unbox(UInt128,x),unbox(Int32,y)))
else
    *(x::Int128,  y::Int128)  = box(Int128,mul_int(unbox(Int128,x),unbox(Int128,y)))
    *(x::UInt128, y::UInt128) = box(UInt128,mul_int(unbox(UInt128,x),unbox(UInt128,y)))

    div(x::Int128,  y::Int128)  = box(Int128,sdiv_int(unbox(Int128,x),unbox(Int128,y)))
    div(x::UInt128, y::UInt128) = box(UInt128,udiv_int(unbox(UInt128,x),unbox(UInt128,y)))

    rem(x::Int128,  y::Int128)  = box(Int128,srem_int(unbox(Int128,x),unbox(Int128,y)))
    rem(x::UInt128, y::UInt128) = box(UInt128,urem_int(unbox(UInt128,x),unbox(UInt128,y)))

    mod(x::Int128, y::Int128) = box(Int128,smod_int(unbox(Int128,x),unbox(Int128,y)))
end

## checked +, - and *

# requires int arithmetic defined, for the loops to work

for T in (Int8,Int16,Int32,Int64)#,Int128) ## FIXME: #4905
    @eval begin
        checked_add(x::$T, y::$T) = box($T,checked_sadd(unbox($T,x),unbox($T,y)))
        checked_sub(x::$T, y::$T) = box($T,checked_ssub(unbox($T,x),unbox($T,y)))
    end
end
for T in (Int16,Int32)
    @eval begin
        checked_mul(x::$T, y::$T) = box($T,checked_smul(unbox($T,x),unbox($T,y)))
    end
end
for T in (UInt8,UInt16,UInt32,UInt64)#,UInt128) ## FIXME: #4905
    @eval begin
        checked_add(x::$T, y::$T) = box($T,checked_uadd(unbox($T,x),unbox($T,y)))
        checked_sub(x::$T, y::$T) = box($T,checked_usub(unbox($T,x),unbox($T,y)))
    end
end
for T in (UInt16,UInt32)
    @eval begin
        checked_mul(x::$T, y::$T) = box($T,checked_umul(unbox($T,x),unbox($T,y)))
    end
end

# checked mul is broken for 8-bit types (LLVM bug?) ## FIXME: #4905

for T in (Int8,UInt8)
    @eval function checked_mul(x::$T, y::$T)
        xy = widemul(x,y)
        (typemin($T) <= xy <= typemax($T)) || throw(OverflowError())
        return xy % $T
    end
end

if WORD_SIZE == 32
for T in (Int64,UInt64)
    @eval function checked_mul(x::$T, y::$T)
        xy = Int128(x)*Int128(y)
        (typemin($T) <= xy <= typemax($T)) || throw(OverflowError())
        return xy % $T
    end
end
else
    checked_mul(x::Int64, y::Int64)   = box(Int64,checked_smul(unbox(Int64,x),unbox(Int64,y)))
    checked_mul(x::UInt64, y::UInt64) = box(UInt64,checked_umul(unbox(UInt64,x),unbox(UInt64,y)))
end

# checked ops are broken for 128-bit types (LLVM bug) ## FIXME: #4905

checked_add(x::Int128, y::Int128) = x + y
checked_sub(x::Int128, y::Int128) = x - y
checked_mul(x::Int128, y::Int128) = x * y

checked_add(x::UInt128, y::UInt128) = x + y
checked_sub(x::UInt128, y::UInt128) = x - y
checked_mul(x::UInt128, y::UInt128) = x * y


## A faster alternative to div if the dividend is reused many times

unsigned_type(::Int8) = UInt8
unsigned_type(::Int16) = UInt16
unsigned_type(::Int32) = UInt32
unsigned_type(::Int64) = UInt64
unsigned_type(::Int128) = UInt128

abstract MultiplicativeInverse{T}

immutable SignedMultiplicativeInverse{T<:Signed} <: MultiplicativeInverse{T}
    divisor::T
    multiplier::T
    addmul::Int8
    shift::UInt8

    function SignedMultiplicativeInverse(d::T)
        ut = unsigned_type(d)
        signedmin = reinterpret(ut, typemin(d))

        ad::ut = abs(d)
        ad <= 1 && error("cannot compute magic for d == $d")
        t::ut = signedmin + signbit(d)
        anc::ut = t - 1 - rem(t, ad)   # absolute value of nc
        p = sizeof(d)*8 - 1            # initialize p
        q1::ut, r1::ut = divrem(signedmin, anc)
        q2::ut, r2::ut = divrem(signedmin, ad)
        while true
            p += 1
            q1 *= 2                    # update q1 = 2p/abs(nc)
            r1 *= 2                    # update r1 = rem(2p/abs(nc))
            if r1 >= anc               # must be unsigned comparison
                q1 += 1
                r1 -= anc
            end
            q2 *= 2                    # update q2 = 2p/abs(d)
            r2 *= 2                    # update r2 = rem(2p/abs(d))
            if r2 >= ad                # must be unsigned comparison
                q2 += 1
                r2 -= ad
            end
            delta::ut = ad - r2
            (q1 < delta || (q1 == delta && r1 == 0)) || break
        end

        m = flipsign((q2 + 1) % T, d)    # resulting magic number
        s = p - sizeof(d)*8                   # resulting shift
        new(d, m, d > 0 && m < 0 ? Int8(1) : d < 0 && m > 0 ? Int8(-1) : Int8(0), UInt8(s))
    end
end
SignedMultiplicativeInverse(x::Signed) = SignedMultiplicativeInverse{typeof(x)}(x)

immutable UnsignedMultiplicativeInverse{T<:Unsigned} <: MultiplicativeInverse{T}
    divisor::T
    multiplier::T
    add::Bool
    shift::UInt8

    function UnsignedMultiplicativeInverse(d::T)
        (d == 0 || d == 1) && error("cannot compute magic for d == $d")
        u2 = convert(T, 2)
        add = false
        signedmin::typeof(d) = one(d) << (sizeof(d)*8-1)
        signedmax::typeof(d) = signedmin - 1
        allones = (zero(d) - 1) % T

        nc::typeof(d) = allones - rem(convert(T, allones - d), d)
        p = 8*sizeof(d) - 1                    # initialize p
        q1::typeof(d), r1::typeof(d) = divrem(signedmin, nc)
        q2::typeof(d), r2::typeof(d) = divrem(signedmax, d)
        while true
            p += 1
            if r1 >= convert(T, nc - r1)
                q1 = q1 + q1 + T(1)     # update q1
                r1 = r1 + r1 - nc       # update r1
            else
                q1 = q1 + q1            # update q1
                r1 = r1 + r1            # update r1
            end
            if convert(T, r2 + T(1)) >= convert(T, d - r2)
                add |= q2 >= signedmax
                q2 = q2 + q2 + 1        # update q2
                r2 = r2 + r2 + T(1) - d # update r2
            else
                add |= q2 >= signedmin
                q2 = q2 + q2            # update q2
                r2 = r2 + r2 + T(1)     # update r2
            end
            delta::typeof(d) = d - 1 - r2
            (p < sizeof(d)*16 && (q1 < delta || (q1 == delta && r1 == 0))) || break
        end
        m = q2 + 1                   # resulting magic number
        s = p - sizeof(d)*8 - add    # resulting shift
        new(d, m % T, add, s % UInt8)
    end
end
UnsignedMultiplicativeInverse(x::Unsigned) = UnsignedMultiplicativeInverse{typeof(x)}(x)

# Special type to handle div by 1
immutable MultiplicativeInverse1{T} <: MultiplicativeInverse{T} end

# div{T}(a::Integer, b::SignedMultiplicativeInverse{T})   = div(convert(T, a), b)
# div{T}(a::Integer, b::UnsignedMultiplicativeInverse{T}) = div(convert(T, a), b)
# rem{T}(a::Integer, b::MultiplicativeInverse{T})         = rem(convert(T, a), b)
# divrem{T}(a::Integer, b::MultiplicativeInverse{T})      = divrem(convert(T, a), b)

function div{T}(a::T, b::SignedMultiplicativeInverse{T})
    x = ((widen(a)*b.multiplier) >>> sizeof(a)*8) % T
    x += (a*b.addmul) % T
    (signbit(x) + (x >> b.shift)) % T
end
function div{T}(a::T, b::UnsignedMultiplicativeInverse{T})
    x = ((widen(a)*b.multiplier) >>> sizeof(a)*8) % T
    x = ifelse(b.add, convert(T, convert(T, (convert(T, a - x) >>> 1)) + x), x)
    x >>> b.shift
end
div{T}(a, ::MultiplicativeInverse1{T}) = convert(T, a)

rem{T}(a::T, b::MultiplicativeInverse{T}) =
    a - div(a, b)*b.divisor
rem{T}(a, ::MultiplicativeInverse1{T}) = zero(T)

function divrem{T}(a::T, b::MultiplicativeInverse{T})
    d = div(a, b)
    (d, a - d*b.divisor)
end
divrem{T}(a, ::MultiplicativeInverse1{T}) = (convert(T, a), zero(T))

# Type unstable!
multiplicativeinverse(x::Signed) = x == 1 ? MultiplicativeInverse1{typeof(x)}() : SignedMultiplicativeInverse(x)
multiplicativeinverse(x::Unsigned) = x == 1 ? MultiplicativeInverse1{typeof(x)}() : UnsignedMultiplicativeInverse(x)
