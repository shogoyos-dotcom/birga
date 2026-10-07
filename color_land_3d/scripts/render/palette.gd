class_name Palette
extends RefCounted

## O'yinchi ranglari va sahna ranglari — "Arcade Grid" uslubidan.

const HEADS: Array[Color] = [
	Color("3d7bff"), Color("ff6b5b"), Color("2fd6a6"), Color("ffc43d"),
	Color("9b6bff"), Color("22d3ee"), Color("ff5ca8"), Color("a3e635"),
	Color("6d8bff"), Color("ff8a4c"), Color("34d399"), Color("e879f9"),
	Color("4cc9f0"), Color("ffd166"), Color("f2545b"), Color("7dd3fc"),
]

## Egallanmagan quruqlik.
const LAND := Color("3b3370")
## Quruqlikning yon devori.
const LAND_SIDE := Color("231c47")
## Okean.
const OCEAN := Color("0b1038")
## Fon va tuman.
const SKY := Color("100e1b")

static func head(index: int) -> Color:
	return HEADS[index % HEADS.size()]

## Hudud rangi — bosh rangdan to'qroq.
static func territory(index: int) -> Color:
	return head(index).darkened(0.18)

## Iz rangi — bosh rangdan ochroq.
static func trail(index: int) -> Color:
	return head(index).lightened(0.3)
