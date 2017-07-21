/* global $ */

$(function(){
	var rotation = 0;

	function onRotateClick(evt){
		rotation += 30;
		$('#demo').css('transform', 'rotate(' + rotation + 'deg)');
	}

	$button = $("<button class='btn'>Rotate</button>");
	$('#demo').after($button);
	$button.on('click', onRotateClick);

});
