
var merchandisingPanel = $('merchcontainer');
var visiblePanel = $('merchcontent'); 

// *****************************************************************************
// scroll panel behavior
// *****************************************************************************

   /***********************************************************
	* Use acc for scrolling value																		*
	* With each interval, acc is increased by INC, until reaching MAX_ACC.	*
	* When interval is cleared, acc is reset to DEF_ACC									*
	* On mousedown, scrolling increases to JUMP value									*
	***********************************************************/
var DEF_ACC = 7;
var INC = 0;
var MAX_ACC = 10;
var JUMP = 20;
var acc = DEF_ACC;
var scrollLeft = null, scrollRight = null, jumpLeft = null, jumpRight = null;

function toggleScrollLeft(eventElement)
{
	switch (eventElement.type)
	{
		case 'mouseover': //slow scrolling
			scrollLeft = setInterval(scrollPanelLeft, 40);
			break;
		case 'mousedown': //quick scrolling	
			if (scrollLeft != null)
				clearInterval(scrollLeft);
			jumpLeft = setInterval(jumpPanelLeft, 40);
			break;
		case 'mouseup': //terminate quick scrolling, resume slow scrolling
			if (jumpLeft != null)
				clearInterval(jumpLeft);
			scrollLeft = setInterval(scrollPanelLeft, 40);
			break;
		default : //terminate all scrolling
			if (scrollLeft != null)
				clearInterval(scrollLeft);
			if (jumpLeft != null)
				clearInterval(jumpLeft);
			acc = DEF_ACC;
			break;		
	}
}
function toggleScrollRight(eventElement)
{
	switch (eventElement.type)
	{
		case 'mouseover': //slow scrolling
			scrollRight = setInterval(scrollPanelRight, 40);
			break;
		case 'mousedown': //quick scrolling		
			if (scrollRight != null)	
				clearInterval(scrollRight);
			jumpRight = setInterval(jumpPanelRight, 40);
			break;
		case 'mouseup': //terminate quick scrolling, resume slow scrolling	
			if (jumpRight != null)		
				clearInterval(jumpRight);
			scrollRight = setInterval(scrollPanelRight, 40);
			break;
		default : //terminate all scrolling
			if (scrollRight != null)
				clearInterval(scrollRight);
			if (jumpRight != null)
				clearInterval(jumpRight);
			acc = DEF_ACC;
			break;		
	}
}
function scrollPanelLeft()
{
	visiblePanel.scrollLeft -= acc;
	if (acc <= MAX_ACC)
		acc += INC;
}
function scrollPanelRight()
{
	visiblePanel.scrollLeft += acc;
	if (acc <= MAX_ACC)
		acc += INC;
}
function jumpPanelLeft()
{
	visiblePanel.scrollLeft -= JUMP;
}
function jumpPanelRight()
{
	visiblePanel.scrollLeft += JUMP;
}

Event.observe($$('#merchleft img').first(), 'mouseover', toggleScrollLeft);
Event.observe($$('#merchright img').first(), 'mouseover', toggleScrollRight);
Event.observe($$('#merchleft img').first(), 'mouseout', toggleScrollLeft);
Event.observe($$('#merchright img').first(), 'mouseout', toggleScrollRight);
Event.observe($$('#merchleft img').first(), 'mousedown', toggleScrollLeft);
Event.observe($$('#merchright img').first(), 'mousedown', toggleScrollRight);
Event.observe($$('#merchleft img').first(), 'mouseup', toggleScrollLeft);
Event.observe($$('#merchright img').first(), 'mouseup', toggleScrollRight);
 
// *****************************************************************************
// resize scrolling panels based on children
// *****************************************************************************
function resizeDynamicScrollingPanels()
{
	var scrollingWrappers = $$('div.scrollingWrapper');
	var productCells = $$('div.scrollingWrapper div.productCell');
	// we need to get this figure now, because the offset width of the visible product
	//  differs from the offsetWidth of the not-visible product
	var productOffsetWidth = productCells.first().offsetWidth;

	scrollingWrappers.each(
		function(currentElement)
		{
			if(currentElement.childElements().size() > 0)
			{
				// make the container big enough to handle all the children
				// the 1.1 is for margin of error
				currentElement.style.width = ((currentElement.childElements().size() * productOffsetWidth) * 1.02) + 'px';
			}
		}
	)
}
Event.observe(window, 'load', resizeDynamicScrollingPanels);
