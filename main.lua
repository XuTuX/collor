------------------------------------------------------------
-- main.lua · 루트 브릿지 (src 디렉토리 래퍼)
------------------------------------------------------------
-- Love2D 가상 파일시스템의 require 검색 경로에 src/ 추가
local requirePath = love.filesystem.getRequirePath()
love.filesystem.setRequirePath(requirePath .. ";src/?.lua;src/?/init.lua")

-- 실제 게임 구현체 로드
require("src.main")
