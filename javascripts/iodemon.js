var IODemon = IODemon || {};

IODemon = (function($, window, document, IOD){

		IOD.LongPoll = {
			doPoll:  function(callback){
				var self = this;
				console.log('poll called')
				if(((IOD.LongPoll.demonChannel == undefined) || (IOD.LongPoll.demonChannel == "")) && ((IOD.LongPoll.demonHash == undefined) || (IOD.LongPoll.demonHash == ""))){
					self.doSubscribe();
				}
				else{
					console.log('No in here');
					window.setTimeout(self.callback, 3000);
				}
		 			
			},

			doSubscribe: function(){
				var self = this;
				$.ajax({
					url: 'http://localhost:3000/subscribe' + '?channel=' + channelName,
					type: 'GET',
					dataType:'text',
					success: function(resp){
						console.log(resp)
						if(resp){
							IOD.LongPoll.demonChannel = channelName;
							IOD.LongPoll.demonHash = resp;
							self.doPoll(self.callback);
						}
					},

					error: function(er, errText){
						console.log(errText);
		 				console.log('error');
		 				console.log(er);
					}
				})
			},

			callback: function(){
				var self = this;
				console.log('in here');
		 		$.ajax({
		 			url: 'http://localhost:3000/poll' + "?channel=" + IOD.LongPoll.demonChannel + "&h=" + IOD.LongPoll.demonHash,
		 			type:'GET',
		 			dataType:'text',
		 			success:function(r){
		 				console.log(r);
		 				console.log('success');
		 				console.log(r);
		 				console.log(self);
		 				IOD.LongPoll.doPoll(IOD.LongPoll.callback);
		 			},
		 			error:function(er, errText){
		 				console.log(errText);
		 				console.log('error');
		 				console.log(er);
		 			}
		 		});		 			
			}
		};

		$(function(){
			IOD.LongPoll.doPoll();
		});

		
	return IOD;
})(jQuery, this, this.document, IODemon);