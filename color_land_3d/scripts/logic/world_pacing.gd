class_name WorldPacing
extends RefCounted

## Xarita hajmi va o'yin sur'ati (Match Pacing) konfiguratsiyasi.
##
## PHASE 3 talabi:
## O'yin maydonini sezilarli darajada kengaytirish, jang vaqtini 8–12 daqiqagacha
## cho'zish, hamda barcha parametrlarni qattiq kodlashsiz, moslanuvchan qilish.

## Shkala variantlari:
##  * 1 — klassik o'lcham (masalan World 460x233, ~33k katak, 2-3 daqiqalik o'yin)
##  * 2 — kengaytirilgan o'lcham (masalan World 920x466, ~132k katak, 8-12 daqiqalik o'yin)
const SCALE_CLASSIC := 1
const SCALE_EXPANDED := 2

## PHASE 3 standarti bo'yicha boshlang'ich shkala:
const DEFAULT_SCALE := 2

## O'yin sur'ati parametrlari (Klassik vs Kengaytirilgan):
const BOTS_CLASSIC := 15
const BOTS_EXPANDED := 20

const SPEED_CLASSIC := 8.0
const SPEED_EXPANDED := 9.5

const TURN_RATE_CLASSIC := 14.0
const TURN_RATE_EXPANDED := 14.0

const START_BLOCK_CLASSIC := 5
const START_BLOCK_EXPANDED := 6

## Kamera parametrlari:
const CAM_HEIGHT_CLASSIC := 36.0
const CAM_BACK_CLASSIC := 30.0
const CAM_FAR_CLASSIC := 400.0

const CAM_HEIGHT_EXPANDED := 42.0
const CAM_BACK_EXPANDED := 35.0
const CAM_FAR_EXPANDED := 650.0

## Shahar nomlari ko'rinish masofasi (katakda):
const NAME_RANGE_CLASSIC := 24.0
const NAME_RANGE_EXPANDED := 36.0

## Maqsadli o'yin davomiyligi (daqiqa):
const TARGET_MATCH_MIN := 8.0
const TARGET_MATCH_MAX := 12.0

static func get_scale() -> int:
	return DEFAULT_SCALE
