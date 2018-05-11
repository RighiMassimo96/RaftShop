include "console.iol"
include "NetworkVisualizerInterface.iol"
include "Time.iol"

outputPort ShopPort1 {
	Location: "socket://localhost:61231"
	Protocol: sodep
	Interfaces: NetworkVisualizerInterface
}
outputPort ShopPort2 {
	Location: "socket://localhost:61232"
	Protocol: sodep
	Interfaces: NetworkVisualizerInterface
}
outputPort ShopPort3 {
	Location: "socket://localhost:61233"
	Protocol: sodep
	Interfaces: NetworkVisualizerInterface
}
outputPort ShopPort4 {
	Location: "socket://localhost:61234"
	Protocol: sodep
	Interfaces: NetworkVisualizerInterface
}
outputPort ShopPort5 {
	Location: "socket://localhost:61236"
	Protocol: sodep
	Interfaces: NetworkVisualizerInterface
}



init
{
  keepRunning = true
}

main{
	while(keepRunning){
		sleep@Time(4000)();
		
		global.currentSending = 1; 
		global.response.status = -1;

		while(global.response.status!=100){
			scope( scope_riceviListe )
			{
		  		install(
		  			ServerOffline => { println@Console("\t\t IOException server from scope 1")() },
		  			IOException => { 
		  				println@Console("\t\t IOException, il SERVER non e' attivo")(); 
		  				global.currentSending ++;
		  				//Se il current sending diventa 6 ripartiamo a inviare la richiesta dal server 1
		  				if( global.currentSending == 6 ) {
		  					global.currentSending = 1
		  				} 
		  			},
		  			ConnectException => { println@Console("\t\t IOException server from scope 3")() }
		 		);
				println@Console("currentSending: "+global.currentSending+"    status: "+global.response.status )();
				sleep@Time(1000)();
				if(global.currentSending == 1){
					println@Console( "Invio a SERVER 1" )();
					riceviListe@ShopPort1(0)(global.response)
				} else if( global.currentSending == 2 ) {
					println@Console( "Invio a SERVER 2" )();
					riceviListe@ShopPort2(0)(global.response)
				} else if( global.currentSending == 3 ) {
					println@Console( "Invio a SERVER 3" )();
					riceviListe@ShopPort3(0)(global.response)
				} else if( global.currentSending == 4 ) {
					println@Console( "Invio a SERVER 4" )();
					riceviListe@ShopPort4(0)(global.response)
				} else if( global.currentSending == 5 ) {
					println@Console( "Invio a SERVER 5" )();
					riceviListe@ShopPort5(0)(global.response)
				};
				if( global.response.status == 0 ) {
					global.currentSending++
					//global.response.status = global.currentSending
				}else{
					global.currentSending = global.response.status
				};

				println@Console( global.response.message )()
			}
		};
		//Dopo che il Network Visualizer ha ricevuto le variabili sullo stato del sistema, le visualizza tramite terminale.

		//Ricevo e stampo lo stato delle merci
		merci << global.response.merciNet;
		println@Console(" SHOP \n")();
		for(x=0, x<#merci.oggetto, x++){
			println@Console("\t "+merci.oggetto[x].nome+" "+merci.oggetto[x].quantita+"\n")()
		};

		//Ricevo e stampo lo stato dei carrelli
		carrelli << global.response.carrelliNet;
		println@Console("\n CARRELLI DISPONIBILI \n")();
		for(x=0, x<#carrelli.carrello, x++){
			println@Console("\t"+carrelli.carrello[x].nome+":")();
		    for (k=0, k<#carrelli.carrello[x].lista.oggetto, k++){
		       	println@Console("\t\t "+carrelli.carrello[x].lista.oggetto[k].nome+" "+
		        carrelli.carrello[x].lista.oggetto[k].quantita+"\n")()
		    }
		};
		undef( carrelli );

		//Ricevo e stampo lo stato dei carrelli archiviati
		carrelliArchivio << global.response.carrelliArchiviatiNet;
		println@Console("\n CARRELLI ARCHIVIATI \n")();
		for(x=0, x<#carrelliArchivio.carrello, x++){
			println@Console("\t"+carrelliArchivio.carrello[x].nome+":")();
		    for (k=0, k<#carrelliArchivio.carrello[x].lista.oggetto, k++){
		       	println@Console("\t\t "+carrelliArchivio.carrello[x].lista.oggetto[k].nome+" "+
		        carrelliArchivio.carrello[x].lista.oggetto[k].quantita+"\n")()
		    }
		}
	}
}
