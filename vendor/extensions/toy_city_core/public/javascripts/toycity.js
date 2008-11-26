function clear_if_default(txt){
	if(txt.value=="keyword(s) or product...") txt.value="" 
}

function fitStringToSize(str,len) {
    var result = str;
    var span = document.createElement("span");
    span.style.visibility = 'hidden';
    span.style.padding = '0px';
    document.body.appendChild(span);
 
    // on first run, check if string fits into the length already.
    span.innerHTML = result;
    if(span.offsetWidth > len) {
        var posStart = 0, posMid, posEnd = str.length;
        while (true) {
            // Calculate the middle position
            posMid = posStart + Math.ceil((posEnd - posStart) / 2);
            // Break the loop if this is the last round
            if (posMid==posEnd || posMid==posStart) break;
 
            span.innerHTML = str.substring(0,posMid) + '&hellip;';
 
            // Test if the width at the middle position is
            // too wide (set new end) or too narrow (set new start).
            if ( span.offsetWidth > len ) posEnd = posMid; else posStart=posMid;
        }
        
        //Escape < and >, eliminate trailing space and a widow character if one is present.
        result = str.substring(0,posStart).replace("<","&lt;").replace(">","&gt;").replace(/(\s.)?\s*$/,'') + '&hellip;';
    }
    document.body.removeChild(span);
    return result;
}