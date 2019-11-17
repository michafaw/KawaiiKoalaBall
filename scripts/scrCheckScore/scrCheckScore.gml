/// scrCheckScore()

var scoreToWin = SCORE_TO_WIN;

if(global.leftScore >= scoreToWin || global.rightScore >= scoreToWin)
	room_goto(roomCredits)