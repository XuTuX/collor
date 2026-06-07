------------------------------------------------------------
-- modifier.lua · 보스 기믹(디버프/규칙 변형) 디스크립션 관리 모듈
------------------------------------------------------------
local Modifier = {}

-- 보스 기믹 이름에 대응하는 유저 인터페이스용 설명 반환
function Modifier.getBossGimmickDesc(gimmick)
    if gimmick == "no_red" then 
        return "빨강 색친구 점수 없음"
    elseif gimmick == "no_black" then 
        return "검정 색친구 점수 없음"
    elseif gimmick == "no_discard" then 
        return "바꾸기 사용 불가"
    elseif gimmick == "high_target" then 
        return "목표 점수 1.5배"
    end
    return "없음"
end

-- 라운드 진입 배너 및 경고용 보스 기믹 설명 반환
function Modifier.getBossGimmickBannerDesc(gimmick)
    if gimmick == "no_red" then 
        return "빨강 색친구 쉬어가기"
    elseif gimmick == "no_black" then 
        return "검정 색친구 쉬어가기"
    elseif gimmick == "no_discard" then 
        return "바꾸기 사용 불가"
    elseif gimmick == "high_target" then 
        return "목표 점수 1.5배 증가"
    end
    return ""
end

return Modifier
