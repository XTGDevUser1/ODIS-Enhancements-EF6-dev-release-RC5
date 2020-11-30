
/*********************************************************************
 * Author:  Kiran Banda
 * Date:    Apr 4,2009
 * Purpose: Validates the fields of types date, integer, and numeric (float)
 *          using open-source validation library.
 *********************************************************************/
//trim the space for the given string ...

function compareDates(date1, dateformat1, date2, dateformat2) {
	var d1 = getDateFromFormat(date1, dateformat1);
	var d2 = getDateFromFormat(date2, dateformat2);
	if (d1 == 0 || d2 == 0) {
		return -1;
	} else {
		if (d1 > d2) {
			return 1;
		}
	}
	return 0;
}

function formatDate(date, format) {
	 
	format = format + "";
	var result = "";
	var i_format = 0;
	var c = "";
	var token = "";
	var y = date.getYear() + "";
	var M = date.getMonth() + 1;
	var d = date.getDate();
	var E = date.getDay();
	var H = date.getHours();
	var m = date.getMinutes();
	var s = date.getSeconds();
	var yyyy, yy, MMM, MM, dd, hh, h, mm, ss, ampm, HH, H, KK, K, kk, k;
	var value = new Object();
	if (y.length < 4) {
		y = "" + (y - 0 + 1900);
	}
	value["y"] = "" + y;
	value["yyyy"] = y;
	value["yy"] = y.substring(2, 4);
	value["M"] = M;
	value["MM"] = LZ(M);
	value["MMM"] = MONTH_NAMES[M - 1];
	value["NNN"] = MONTH_NAMES[M + 11];
	value["d"] = d;
	value["dd"] = LZ(d);
	value["E"] = DAY_NAMES[E + 7];
	value["EE"] = DAY_NAMES[E];
	value["H"] = H;
	value["HH"] = LZ(H);
	if (H == 0) {
		value["h"] = 12;
	} else {
		if (H > 12) {
			value["h"] = H - 12;
		} else {
			value["h"] = H;
		}
	}
	value["hh"] = LZ(value["h"]);
	if (H > 11) {
		value["K"] = H - 12;
	} else {
		value["K"] = H;
	}
	value["k"] = H + 1;
	value["KK"] = LZ(value["K"]);
	value["kk"] = LZ(value["k"]);
	if (H > 11) {
		value["a"] = "PM";
		//KB: Introduced "tt" which is equivalent of saying AM/PM
		value["tt"] = "PM";		
	} else {
		value["a"] = "AM";
		//KB: Introduced "tt" which is equivalent of saying AM/PM
		value["tt"] = "AM";
	}
	value["m"] = m;
	value["mm"] = LZ(m);
	value["s"] = s;
	value["ss"] = LZ(s);
	while (i_format < format.length) {
		c = format.charAt(i_format);
		token = "";
		while ((format.charAt(i_format) == c) && (i_format < format.length)) {
			token += format.charAt(i_format++);
		}
		if (value[token] != null) {
			result = result + value[token];
		} else {
			result = result + token;
		}
	}
	return result;
}

// Parse Time string (24-hr format)
function isValidTime(val) {
 
//KB: Older approach. 
	//var expression = "^(0?[0-9]|1?[0-9]|2?[0-3]):([0-5][0-9])(:([0-5][0-9]))?$"; // KB: Make the seconds validation optional
	//var expression = "^(0?[0-9]|1?[0-9]|2?[0-3]):([0-5][0-9])$"; //New: interprets time in HH:MM format
//	var regExp = new RegExp(expression);
//	if (val.match(regExp)) {
//		return true;
//	} else {
//		return false;
//	}

//KB: Considering institution time format settings to validate time input

    var retVal = getDateFromFormat(val,lblZIMSTimeFormat);
    if(retVal == 0)
    {
        return false;
    }
    else
    {
        return true;
    }

}

// ===================================================================
// Author of the library: Matt Kruse <matt@mattkruse.com>
// WWW: http://www.mattkruse.com/
//
// NOTICE: You may use this code for any purpose, commercial or
// private, without any further permission from the author. You may
// remove this notice from your final code if you wish, however it is
// appreciated by the author if at least my web site address is kept.
//
// ===================================================================
var MONTH_NAMES = new Array("Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember", "Jan", "Feb", "Mrz", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez");
var DAY_NAMES = new Array("Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
function LZ(x) {
	return (x < 0 || x > 9 ? "" : "0") + x;
}

// ------------------------------------------------------------------
// isDate ( date_string, format_string )
// Returns true if date string matches format of format string and
// is a valid date. Else returns false.
// It is recommended that you trim whitespace around the value before
// passing it to this function, as whitespace is NOT ignored!
// ------------------------------------------------------------------
function isDate(val, format) {
	var date = getDateFromFormat(val, format);
	if (date == 0) {
		return false;
	}
	return true;
}

	
// ------------------------------------------------------------------
// Utility functions for parsing in getDateFromFormat()
// ------------------------------------------------------------------
function _isInteger(val) {

	var digits = "1234567890";
	for (var i = 0; i < val.length; i++) {
		if (digits.indexOf(val.charAt(i)) == -1) {
			return false;
		}
		
	}
	return true;
}
function _isIntegerGreaterThanZero(val) {

	var digits = "1234567890";
	for (var i = 0; i < val.length; i++) {
		if (digits.indexOf(val.charAt(i)) == -1) {
			return false;
		}
		if(val==0)
		{
		return false;
		}
	}
	return true;
}
function _isPositiveInteger(val) {
	var digits = "123456789";
	for (var i = 0; i < val.length; i++) {
		if (digits.indexOf(val.charAt(i)) == -1) {
			return false;
		}
	}
	return true;
}
function _getInt(str, i, minlength, maxlength) {
	for (var x = maxlength; x >= minlength; x--) {
		var token = str.substring(i, i + x);
		if (token.length < minlength) {
			return null;
		}
		if (_isInteger(token)) {
			return token;
		}
	}
	return null;
}
	
// ------------------------------------------------------------------
// getDateFromFormat( date_string , format_string )
//
// This function takes a date string and a format string. It matches
// If the date string matches the format string, it returns the
// getTime() of the date. If it does not match, it returns 0.
// ------------------------------------------------------------------
function getDateFromFormat(val, format) {
	val = val + "";
	format = format + "";
	var i_val = 0;
	var i_format = 0;
	var c = "";
	var token = "";
	var token2 = "";
	var x, y;
	var now = new Date();
	var year = now.getYear();
	var month = now.getMonth() + 1;
	var date = 1;
	var hh = 0; //now.getHours(); //Intialyzed to zero
	var mm = 0; //now.getMinutes();//Intialyzed to zero
	var ss = 0; //now.getSeconds();//Intialyzed to zero
	var ampm = "";
	
	while (i_format < format.length) {
		// Get next token from format string
		c = format.charAt(i_format);
		token = "";
		while ((format.charAt(i_format) == c) && (i_format < format.length)) {
			token += format.charAt(i_format++);
		}		  
		// Extract contents of value based on format token
		// KB: Compare year without case
		var originalToken = token;
		token = token.toLowerCase(); // Lower the case and compare against year format	
		
			
		if (token == "yyyy" || token == "yy" || token == "y") {
			if (token == "yyyy") {
				x = 4;
				y = 4;
			}
			if (token == "yy") {
				x = 2;
				y = 2;
			}
			if (token == "y") {
				x = 2;
				y = 4;
			}
			year = _getInt(val, i_val, x, y);	
					
			if (year == null) {
				return 0;
			}
			i_val += year.length;
			if (year.length == 2) {
				if (year > 70) {
					year = 1900 + (year - 0);
				} else {
					year = 2000 + (year - 0);
				}
			}
			// KB: Raise error if the year is less than 1900
			if(year < 1900)
			{
			    return 0;
			}
			
		} else {
		    // KB: Reset the token to the original
		    token = originalToken;
			if (token == "MMM" || token == "NNN") {
				month = 0;
				for (var i = 0; i < MONTH_NAMES.length; i++) {
					var month_name = MONTH_NAMES[i];
					if (val.substring(i_val, i_val + month_name.length).toLowerCase() == month_name.toLowerCase()) {
						if (token == "MMM" || (token == "NNN" && i > 11)) {
							month = i + 1;
							if (month > 12) {
								month -= 12;
							}
							i_val += month_name.length;
							break;
						}
					}
				}
				if ((month < 1) || (month > 12)) {
					return 0;
				}
				
			} else {
			    // KB: Reset the token to the original
		        token = originalToken;
				if (token == "EE" || token == "E") {
					for (var i = 0; i < DAY_NAMES.length; i++) {
						var day_name = DAY_NAMES[i];
						if (val.substring(i_val, i_val + day_name.length).toLowerCase() == day_name.toLowerCase()) {
							i_val += day_name.length;
							break;
						}
					}
				} else {
				    // KB: Reset the token to the original
		            token = originalToken;
					if (token == "MM" || token == "M") {
						month = _getInt(val, i_val, token.length, 2);
						if (month == null || (month < 1) || (month > 12)) {
							return 0;
						}
						i_val += month.length;
						
					} else { // KB: Token is already in lower case
					   // token = token.toLowerCase();
						if (token == "dd" || token == "d") {
							
							date = _getInt(val, i_val, token.length, 2);
							
							if (date == null || (date < 1) || (date > 31)) {
								return 0;
							}
							i_val += date.length;
							
						} else { // KB: Token is already in lower case						    
							if (token == "hh" || token == "h") {
								hh = _getInt(val, i_val, token.length, 2);
								if (hh == null || (hh < 1) || (hh > 12)) {
									return 0;
								}
								i_val += hh.length;
							} else {
							    // KB: Reset the token to the original
		                        token = originalToken;
								if (token == "HH" || token == "H") {
									hh = _getInt(val, i_val, token.length, 2);
									if (hh == null || (hh < 0) || (hh > 23)) {
										return 0;
									}
									i_val += hh.length;
								} else {
								    // KB: Reset the token to the original
		                            token = originalToken;
									if (token == "KK" || token == "K") {
										hh = _getInt(val, i_val, token.length, 2);
										if (hh == null || (hh < 0) || (hh > 11)) {
											return 0;
										}
										i_val += hh.length;
									} else {
										if (token == "kk" || token == "k") {
											hh = _getInt(val, i_val, token.length, 2);
											if (hh == null || (hh < 1) || (hh > 24)) {
												return 0;
											}
											i_val += hh.length;
											hh--;
										} else {
											if (token == "mm" || token == "m") {
												mm = _getInt(val, i_val, token.length, 2);
												if (mm == null || (mm < 0) || (mm > 59)) {
													return 0;
												}
												i_val += mm.length;
											} else {
												if (token == "ss" || token == "s") {
													ss = _getInt(val, i_val, token.length, 2);
													if (ss == null || (ss < 0) || (ss > 59)) {
														return 0;
													}
													i_val += ss.length;
												} else { // KB: consider "tt" and parse AM/PM value in time
													if (token == "a" || token == "tt") {
														if (val.substring(i_val, i_val + 2).toLowerCase() == "am") {
															ampm = "AM";
														} else {
															if (val.substring(i_val, i_val + 2).toLowerCase() == "pm") {
																ampm = "PM";
															} else {
																return 0;
															}
														}
														i_val += 2;
													} else {
														if (val.substring(i_val, i_val + token.length) != token) {
															return 0;
														} else {
															i_val += token.length;
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	// If there are any trailing characters left in the value, it doesn't match
	if (i_val != val.length) {
		return 0;
	}
	// Is date valid for month?
	if (month == 2) {
		// Check for leap year
		if (((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0)) { // leap year
			if (date > 29) {
				return 0;
			}
		} else {
			if (date > 28) {
				return 0;
			}
		}
	}
	if ((month == 4) || (month == 6) || (month == 9) || (month == 11)) {
		if (date > 30) {
			return 0;
		}
	}
	// Correct hours value
	if (hh < 12 && ampm == "PM") {
		hh = hh - 0 + 12;
	} else {
		if (hh > 11 && ampm == "AM") {
			hh -= 12;
		}
	}
	var newdate = new Date(year, month - 1, date, hh, mm, ss);
	return newdate.getTime();
}

// ------------------------------------------------------------------
// parseDate( date_string [, prefer_euro_format] )
//
// This function takes a date string and tries to match it to a
// number of possible date formats to get the value. It will try to
// match against the following international formats, in this order:
// y-M-d   MMM d, y   MMM d,y   y-MMM-d   d-MMM-y  MMM d
// M/d/y   M-d-y      M.d.y     MMM-d     M/d      M-d
// d/M/y   d-M-y      d.M.y     d-MMM     d/M      d-M
// A second argument may be passed to instruct the method to search
// for formats like d/M/y (european format) before M/d/y (American).
// Returns a Date object or null if no patterns match.
// ------------------------------------------------------------------
function parseDate(val) {
	var preferEuro = (arguments.length == 2) ? arguments[1] : false;
	generalFormats = new Array("y-M-d", "MMM d, y", "MMM d,y", "y-MMM-d", "d-MMM-y", "MMM d");
	monthFirst = new Array("M/d/y", "M-d-y", "M.d.y", "MMM-d", "M/d", "M-d");
	dateFirst = new Array("d/M/y", "d-M-y", "d.M.y", "d-MMM", "d/M", "d-M");
	var checkList = new Array("generalFormats", preferEuro ? "dateFirst" : "monthFirst", preferEuro ? "monthFirst" : "dateFirst");
	var d = null;
	for (var i = 0; i < checkList.length; i++) {
		var l = window[checkList[i]];
		for (var j = 0; j < l.length; j++) {
			d = getDateFromFormat(val, l[j]);			
			if (d != 0) {
				return new Date(d);
			}
		}
	}
	return null;
}

//
function isNumeric(val) {
	return (parseFloat(val, 10) == (val * 1));
}
function isPositiveNumeric(val) {
	if (isNaN(val * 1)) {
		return false;
	}
	var checkNum = parseFloat(val);
	if (isNaN(checkNum)) {
		return false;
	} else {
		if (checkNum < 0) {
			return false;
		}
	}
	return true;
}
function isPositiveNumericGraterThanZero(val) {
	if (isNaN(val * 1)) {
		return false;
	}
	var checkNum = parseFloat(val);
	if (isNaN(checkNum)) {
		return false;
	} else {
		if (checkNum <= 0) {
			return false;
		}
	}
	return true;
}
function isPercent(val) {
	return (((val * 1) >=0) && ((val * 1) <=100));
}

String.format = function( text )
{
    //check if there are two arguments in the arguments list
    if ( arguments.length <= 1 )
    {
        //if there are not 2 or more arguments there's nothing to replace
        //just return the original text
        return text;
    }
    //decrement to move to the second argument in the array
    var tokenCount = arguments.length - 2;
    for( var token = 0; token <= tokenCount; token++ )
    {
        //iterate through the tokens and replace their placeholders from the original text in order
        text = text.replace( new RegExp( "\\{" + token + "\\}", "gi" ),
                                                arguments[ token + 1 ] );
    }
    return text;
};