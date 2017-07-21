/* global $ */

$(function(){
	var direction = 1

	function onMoveClick(evt){
		direction = -1 * direction;
		$('#demo').css('transform', 'translateX(' + (100 * direction) + 'px)');
	}

	$button = $("<button class='btn'>Move</button>");
	$('#demo').after($button);
	$button.on('click', onMoveClick);

});
