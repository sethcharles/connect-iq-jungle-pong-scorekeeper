using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Timer as Timer;
using Toybox.Attention as Attention;

var app;

var crnt_score;
var win_cnt;
var lose_cnt;

enum
{
	REC_WIN_CNT,
	REC_LOSE_CNT,
	GAME_MAX_PNTS
}

var rec_win_cnt;
var rec_lose_cnt;

var game_max_pnts;

var system_settings;

class JunglePongApp extends App.AppBase {

    //! onStart() is called on application start up
    function onStart() {
    
    	app = App.getApp();
    		
    	crnt_score = 0;
    	win_cnt = 0;
    	lose_cnt = 0;
    	
    	rec_win_cnt = getProperty(REC_WIN_CNT);
    	rec_lose_cnt = getProperty(REC_LOSE_CNT);
    	
    	if (rec_win_cnt == null) {
    		rec_win_cnt = 0;
    		rec_lose_cnt = 0;
    		app.setProperty(REC_WIN_CNT, rec_win_cnt);
    		app.setProperty(REC_LOSE_CNT, rec_lose_cnt);
    	}
    	
    	game_max_pnts = getProperty(GAME_MAX_PNTS);
    	
		if (game_max_pnts == null) {
    		game_max_pnts = 3;
    		app.setProperty(game_max_pnts, GAME_MAX_PNTS);
    	}
    	
    	system_settings = Sys.getDeviceSettings();
    }

    //! onStop() is called when your application is exiting
    function onStop() {
    	Sys.println("STOPPING");
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new JunglePongView(), new JunglePongDelegate() ];
    }

}

class JunglePongDelegate extends Ui.BehaviorDelegate {

    function onMenu() {
        Ui.pushView(new Rez.Menus.MainMenu(), new JunglePongMenuDelegate(), Ui.SLIDE_UP);
        return true;
    }
    
    //! Increment current score
    function onPreviousPage() {
    	crnt_score = ( crnt_score < game_max_pnts ) ? crnt_score + 1 : game_max_pnts;
    	
    	if (crnt_score == game_max_pnts) {
    		Attention.playTone(Attention.TONE_ERROR);
    	} else {
    		Attention.playTone(Attention.TONE_KEY);
    	}
    	
    	Ui.requestUpdate();
    }
    
    //! Decrement current score 
    function onNextPage() {
    	
    	Attention.playTone(Attention.TONE_KEY);
    	    
    	crnt_score = ( crnt_score > 0 ) ? crnt_score - 1 : 0;
    	Ui.requestUpdate();
    }
    
    //! End current game and update match wins or losses
    function onKey(evt) {
    	var handled = false;
    	var key = evt.getKey();
    	
    	if (key == KEY_ENTER) {
    		
    		if (crnt_score < game_max_pnts) {
    			win_cnt = win_cnt + 1;
    			rec_win_cnt = rec_win_cnt + 1;
    			app.setProperty(REC_WIN_CNT, rec_win_cnt);
    		}
    		else {
    			lose_cnt = lose_cnt + 1;
    			rec_lose_cnt = rec_lose_cnt + 1;
    			app.setProperty(REC_LOSE_CNT, rec_lose_cnt);
    		}
    		    		    		
    		crnt_score = 0;
    		
    		handled = true;
    	}
    	   	
    	Ui.requestUpdate();
    	
    	return handled;
    }

}

class JunglePongView extends Ui.View {

	var crnt_score_label;
	var win_cnt_label;
	var lose_cnt_label;
	var time_label;
	
	var clock_timer;

	function clockUpdate() {
		var clockTime  = Sys.getClockTime();
		var hour       = clockTime.hour;
		var min        = clockTime.min;
		var amPm       = "";
		var timeString = "";
		
		if (!system_settings.is24Hour) {
			// Determine if we should show "am" or "pm"
			amPm = (hour > 11) ? "pm" : "am";
			
			// Reduce hour and correct hour "0" which is "12" on the clock
			hour = hour % 12;
			hour = (hour == 0) ? 12 : hour;
			
			// Format time string
			timeString = Lang.format("$1$:$2$$3$", [hour, min.format("%02d"), amPm]);	
		}
		else {
			// Format time string
			timeString = Lang.format("$1$:$2$", [hour, min.format("%02d")]);
		}
		
		time_label.setText(timeString);
		Ui.requestUpdate();
	}

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
        
        crnt_score_label = View.findDrawableById("crnt_score_label");
        win_cnt_label    = View.findDrawableById("win_cnt_label");
        lose_cnt_label   = View.findDrawableById("lose_cnt_label");
        time_label       = View.findDrawableById("time_label");
        
        clockUpdate();
        
        clock_timer = new Timer.Timer();
		clock_timer.start( method(:clockUpdate), 1000, true);
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        
        crnt_score_label.setText(crnt_score.toString());
		win_cnt_label.setText(win_cnt.toString());
		lose_cnt_label.setText(lose_cnt.toString());

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
    
}

class JunglePongMenuDelegate extends Ui.MenuInputDelegate {

    function onMenuItem(item) {
        if (item == :main_item_help) {
        	Ui.pushView(new JunglePongRecordsView(), new JunglePongRecordsDelegate(), Ui.SLIDE_UP);
        } else if (item == :main_item_records) {
            Ui.pushView(new JunglePongRecordsView(), new JunglePongRecordsDelegate(), Ui.SLIDE_UP);
        } else if (item == :main_item_settings) {
        	Sys.println("item settings");
        }
    }

}

class JunglePongRecordsView extends Ui.View {

	var record_win_cnt_label;
	var record_lose_cnt_label;

    //! Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.RecordsLayout(dc));
        
        record_win_cnt_label    = View.findDrawableById("record_win_cnt_label");
        record_lose_cnt_label   = View.findDrawableById("record_lose_cnt_label");
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Update the view
    function onUpdate(dc) {
        
        record_win_cnt_label.setText(rec_win_cnt.toString());
		record_lose_cnt_label.setText(rec_lose_cnt.toString());

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }
    
}
class JunglePongRecordsDelegate extends Ui.BehaviorDelegate {
     
     function onBack() {
     	Ui.popView(Ui.SLIDE_DOWN);
     	return true;
     }
     
    function onMenu() {
        Ui.pushView(new Ui.Confirmation("Delete records?"), new JunglePongsRecordsDeleteConfirmationDelegate(), Ui.SLIDE_UP);
        return true;
    }
}

class JunglePongsRecordsDeleteConfirmationDelegate extends Ui.ConfirmationDelegate {

	function onResponse(response) {
	
		if (response == CONFIRM_YES) {
			rec_win_cnt = 0;
    		rec_lose_cnt = 0;
    		app.setProperty(REC_WIN_CNT, rec_win_cnt);
    		app.setProperty(REC_LOSE_CNT, rec_lose_cnt);
		}
		
	}
		
}