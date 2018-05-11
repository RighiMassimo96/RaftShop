include "console.iol"
include "time.iol"
include "RaftInterface.iol"
include "math.iol"
include "AdministratorInterface.iol"
include "ClientInterface.iol"
include "NetworkVisualizerInterface.iol"
include "semaphore_utils.iol"


inputPort Server2 {
	Location: "socket://localhost:61232"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}

//5 output port a tutti i server.Anche server 2

outputPort ToServer1 {
	Location: "socket://localhost:61231"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}
outputPort ToServer2 {
	Location: "socket://localhost:61232"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}
outputPort ToServer3 {
	Location: "socket://localhost:61233"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}
outputPort ToServer4 {
	Location: "socket://localhost:61234"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}
outputPort ToServer5 {
	Location: "socket://localhost:61236"
	Protocol: sodep
	Interfaces: RaftInterface, AdministratorInterface, ClientInterface, NetworkVisualizerInterface
}


execution{ concurrent }

/*
In questa procedura andiamo a definire i semafori che utilizzeremo per gestire la concorrenza
all'interno del Raft Shop.
*/
define semafori {
	global.semaforoCarrelli = null;	//Questo semaforo lo utilizziamo per le operazioni sulla lista dei carrelli (variabile globale)
	global.semaforoMerci = null;	//Questo semaforo lo utilizziamo per le operazioni sulla lista delle merci (variabile globale)

	
	with(global.semaforoCarrelli){
  	.name = "semaforoCarrelli";	//nome del semaforo
  	.permits = 1  // valore massimo che può assumere il semaforo

  	};
  	
	release@SemaphoreUtils( global.semaforoCarrelli )( res ); //rendo disponibile il semaforo dei carrelli

	
	with(global.semaforoMerci){
		.name = "semaforoMerci";	//nome del semaforo
		.permits = 1  // valore massimo che può assumere il semaforo

	};
	
	release@SemaphoreUtils( global.semaforoMerci )( res ) //rendo disponibile il semaforo delle merci


 // acquire@SemaphoreUtils( global.semaforoStato )( res ) //decrementa
 // release@SemaphoreUtils( global.semaforoStato )( res ) //incrementa
 // 1 libero
 // 0 occupato

}

/*
Con l'operazione sendRequestVote un server può inviare una richiesta di voto agli altri server.
*/
define sendRequestVote
{

	termineIdServer.idS = global.iD_Server;
	termineIdServer.termine = global.termineServer;

    /*
    In questo scope gestisco i guasti, installando dei gestori di eccezioni.
    Se per esempio un server va in crash, questa eccezione verrà gestita.
    */
	scope( s )
	{
	  install(
	  	serverOffline => { println@Console("\t\t IOException server from scope 1")() },
	  	IOException => { println@Console("\t\t IOException server from scope 2")() },
	  	ConnectException => { println@Console("\t\t IOException server from scope 3")() }
	  );

	  //println@Console("TermineIdServer: "+termineIdServer.idS)();
	  
	  //Il server candidato invia in parallelo le richieste di voto a tutti gli altri server
	  sendRequestVote@ToServer1 (termineIdServer)(risposta1)|
	  sendRequestVote@ToServer3 (termineIdServer)(risposta3)|
	  sendRequestVote@ToServer4 (termineIdServer)(risposta4)|
	  sendRequestVote@ToServer5 (termineIdServer)(risposta5)
	};

	global.serverNumeroVoti = 1; //Il server vota già per se stesso

	/*
	In base alla risposta che riceverà alla sua richiesta il server candidato (0 votato, 1 non votato)
	il server incrementerà o no il suo numero di voti.
	*/
	if(risposta1 == 1){ 
		global.serverNumeroVoti ++;
		println@Console( "Server 1 ha votato per me" )()
	};
	//if(risposta2 == 1){ global.serverNumeroVoti ++};
	if(risposta3 == 1){ 
		global.serverNumeroVoti ++;
		println@Console( "Server 3 ha votato per me" )()
	};
	if(risposta4 == 1){ 
		global.serverNumeroVoti ++;
		println@Console( "Server 4 ha votato per me" )()
	};
	if(risposta5 == 1){ 
		global.serverNumeroVoti ++;
		println@Console( "Server 5 ha votato per me" )()
	};

	//Se il server ha la maggioranza dei voti (3/5) allora diventa leader
	if( global.serverNumeroVoti >= 3 ) {
	  global.stato = 3; //il server diventa leader
	  global.iD_ServerLeader = global.iD_Server
	}
}

/*
Questa procedura implementa l'invio in parallelo del segnale di heartbeat.
Si invia la variabile termineIdServer che contiene l'ID del server leader e il suo termine corrente.
*/
define sendHeartBeat{

	termineIdServer.idS = global.iD_Server;
	termineIdServer.termine = global.termineServer;
	scope( s )
	{
	  install(
	  	serverOffline => { println@Console("\t\t IOException server from scope 1")() },
	  	IOException => { println@Console("\t\t IOException server from scope 2")() },
	  	ConnectException => { println@Console("\t\t IOException server from scope 3")() }
	  );

	  //println@Console("TermineIdServer: "+global.termineIdServer.idS)();

	  //Si inviano i segnali in parallelo agli altri server
	  sendHeartBeat@ToServer1 (termineIdServer)(risposta1)|
	  sendHeartBeat@ToServer3 (termineIdServer)(risposta3)|
	  sendHeartBeat@ToServer4 (termineIdServer)(risposta4)|
	  sendHeartBeat@ToServer5 (termineIdServer)(risposta5)
	}

}

/*
Questa procedura serve per agiornare lo stato e le variabili globali di ogni server ogni volta che 
all'interno del raft viene effettuata/richiesta un operazione.
Questa procedura viene inviata dal server leader agli altri server.
Il suo invio coincide con la fine dell'operazione richiesta.
*/
define sincronizzaServers{
		
		/*
		Invio le variabili globali tramite la macro-variabile syncro.
		*/
		global.syncro.merci << global.listaMerci;
		global.syncro.indiceM = global.indiceProdotto;
		undef( global.syncro.carrelli );
		global.syncro.carrelli << global.listaCarrelli;
		global.syncro.indiceC = global.indiceCarrello;
		global.syncro.carrelliArchiviati << global.listaCarrelliArchiviati;
		global.syncro.indiceCA = global.indiceCarrelloArchiviato;
		global.syncro.merceCaricata = global.administratorHaCaricato;
		global.syncro.id = int(global.iD_Server);

		scope( s )
		{
			install(
				serverOffline => { println@Console("\t\t IOException server from scope 1")() },
				IOException => { println@Console("\t\t IOException server from scope 2")() },
				ConnectException => { println@Console("\t\t IOException server from scope 3")() }
			);


			sincronizzaServers@ToServer1 (global.syncro)(risposta1)|
			sincronizzaServers@ToServer3 (global.syncro)(risposta3)|
			sincronizzaServers@ToServer4 (global.syncro)(risposta4)|
			sincronizzaServers@ToServer5 (global.syncro)(risposta5)
		}



}

define settaNuovoTimeout{
	//Ogni volta che chiamo SettaNuovoTimeout mi setta un nuovo Timeout sommandogli un numero random compreso tra 0 e 10
	random@Math()(rnd);
	/*
	Se il numero casuale è 0, aggiungo 1, cosicchè
	l'Election Timeout non sia mai lo stesso.
	*/
	if( int(rnd*10) == 0 ) {
	  	rnd += 0.1
	};
	global.TimeForNextTimeout = global.Timer + (rnd*10) + 3
	//Si è aggiunto +3 per ampliare l'Election Timeout e permettere una lettura megliore dei meccanismi del raft
}


/*
Ciclo infinito che mi rappresenta la vita/processo del server.
*/
define infiniteLoop{
	//For che tende all'infinito
	for ( i = 0, i>-1, i++ ){

		//println@Console( "Prima degli if" )();
		sleep@Time(2000)();
		/*
		Ogni volta che il server va in Election Timeout diventa candidato e inizia una nuova elezione.
		Per iniziare una nuova elezione, il candidato incrementa il proprio termine corrente, vota per se stesso 
		e invia in parallelo a tutti i server la richiesta di voto tramite l'operazione sendRequestVote.
		*/
		if( global.Timer >= global.TimeForNextTimeout && global.stato != 3){
		  	
		  	//println@Console( "Dentro prima parentesi" )();
			println@Console( "SONO CANDIDATE" )();
		  	global.stato = 2;	//il server diventa candidate
		  	//quando il server diventa candidate non sa più chi è il leader.
		  	//Percui se un client glielo chiedesse, il server gli risponderà 0.
		  	global.iD_ServerLeader = 0;  
		  	println@Console( "RV >>>>" )();
		  	settaNuovoTimeout;	//Alla richiesta di voti i candidati fanno partire un Election Timeout
		  	global.termineServer++;	//Incrementa il proprio termine corrente
		  	sendRequestVote	//Invia la richiesta di voto
		  	

		  	//println@Console("TermineIdServer: "+termineIdServer.idS)()
		};

		/*
		Se il server è leader, allora invia l'heartbeat ogni tot di tempo, in questo caso 2 "Timer".
		*/
		if( global.stato == 3 && global.Timer % 2 == 0){
		  	/*
		  	sendHertBeat = quando il timer è multiplo di 2 invio l'heartbeat, anche questa funzione la definisco sopra l'init
		  	*/
		  	//println@Console( "Dentro seconda parentesi" )();
		  	println@Console( "HB >>>>" )();
		  	sendHeartBeat
		};

		global.Timer++;	//Incremento il Timer

		//Questa stampa aiuta a visualizzare i valori delle variabili utilizzate nel Raft ad ogni Timer.
		println@Console(
		global.iD_Server+") "
		+global.Timer+"\t"
		+global.TimeForNextTimeout+"\t"
		+global.termineServer+"\t("
		+global.stato+")\t"
		+global.iD_ServerLeader+"\t"
		)()
	}
}

/*
Ogni server ha:
- 1 Timer = clock alive, cioè da quanto tempo è vivo il server (parte da 0,1,2,.....)
- 1 ID Server = numero intero fisso e proprio, non cambia mai,  identifica il server
- 1 ID Server Leader = numero intero, cambia ogni volta che cambia il leader
- 1 TimeForNextTimeout
- 1 Termine del Server = intervalli in cui è suddiviso il tempo
- 1 Stato (1=Follower, 2=Candidate, 3=Leader)
*/


init{
	semafori;	//Inizializzo i semafori

	//Variabili per il raft
	global.Timer = 0; //Variabile che mi rappresenta il tempo che scorre all'interno di ogni termine (nel processo del server)
	global.iD_Server = 2; //ID del server, ogni server ha un ID diverso
	global.iD_ServerLeader = 0; //ID del server leader, all'inizio è settato a zero, dato che non c'è un leader
	global.TimeForNextTimeout = 0; //Tempo di Election Timeout, quando viene raggiunto dal Timer, si passa ad un altro termine
	settaNuovoTimeout;	//Setto/aggiorno un nuovo Election Timeout
	global.termineIdServer.idS = global.iD_Server;	//1,2,3,...
	global.termineServer = 0; //Ogni termine inizia con un elezione nella quale i candidati cercano di diventare leader
	global.stato = 1; //Chiaramente al suo avvio il server è follower

	//Variabili per il dialogo con l'Administrator
	global.administratorHaCaricato = false; //diventa true quando l'administrator mi carica inizialmente le merci nello Shop
	global.indiceProdotto = 4; //inizialmente ci sono 4 tipi di oggetti/prodotti nello Shop
	prodottiCaricati = false; //Nell'operazione di aggiunta di elementi all'interno di un carrello utilizziamo questa variabile.

	//Variabili per il dialogo con il Client
	global.indiceCarrello = 0;	//Indice della lista globale dei carrelli nello Shop
  	global.indiceCarrelloArchiviato = 0;  //Indice della lista globale dei carrelli archiviati nello Shop

	println@Console( "Prima dell'invio" )();
	startServer@ToServer2(t)  //Richiamo l'operazione startServer che mi fa partire il processo del server (loop infinito).
}

main
{

//******************************OPERAZIONI PER L'ALGORITMO RAFT*************************************************

	/*
	Questa operazione mi permette di avviare il processo del server.
	In essa è contenuto il ciclo infinito infiniteLoop che mi rappresenta la durata
	del processo del server.
	*/
	[startServer( creazione )] {
		//risposteServer
		println@Console( "Dentro startServer" )();
		infiniteLoop
	}

	/*
	Questa operazione permette al server leader di replicare gli aggiornamenti fatti sulle variabili globali
	anche negli altri servers.
	A questo scopo viene utilizzata una macro-variabile "syncro", la quale "trasporta" tutte le variabili 
	globali ad ogni servers. I servers infine aggiorneranno le proprie variabili. 
	*/
	[sincronizzaServers( syncro )( daRispondere ) {
		println@Console( "<<<< SYNC" )();
		acquire@SemaphoreUtils( global.semaforoCarrelli )( res );
		acquire@SemaphoreUtils( global.semaforoMerci )( res );
		undef( global.listaCarrelli);
		undef( global.listaMerci);
		for ( i = 0, i<#syncro.merci.oggetto, i++ ) {
		  	println@Console(syncro.merci.oggetto[i].nome+" ---> "+syncro.merci.oggetto[i].quantita)()
		};
		println@Console( "Carrelli aggiornati" )();
		for ( i = 0, i<#syncro.carrelli.carrello, i++ ) {
		  	println@Console(syncro.carrelli.carrello.nome)()
		};
		global.listaCarrelli << syncro.carrelli;
		global.indiceCarrello = syncro.indiceC;
		global.listaCarrelliArchiviati << syncro.carrelliArchiviati;
		global.indiceCarrelloArchiviato = syncro.indiceCA;
		global.listaMerci << syncro.merci;
		global.indiceProdotto = syncro.indiceM;
		global.administratorHaCaricato = syncro.merceCaricata;
		//println@Console( "syncro.merceCaricata = "+syncro.merceCaricata)();
		//println@Console( "administratorHaCaricato = "+global.administratorHaCaricato)();
		global.iD_ServerLeader = int(syncro.id);
		release@SemaphoreUtils( global.semaforoMerci )( res );
		release@SemaphoreUtils( global.semaforoCarrelli )( res );
		daRispondere = 1
	}]


	/*
	Con questa operazione il server riceve l'heartbeat dal server leader.
	Ricevendo l'heartbeat, il server aggiorna il suo iD_ServerLeader, dato che, essendo in grado
	solamente il server leader di inviare l'heartbeat, il server non leader sarà sicuro che quello 
	è il leader.
	Quando il server recepisce chi è il server leader, diventa suo follower e aggiorna il suo termine
	con quello del leader.
	*/
	[sendHeartBeat( termineIdServer )( daRispondere ) {
		println@Console( "<<<< HB" )();
		global.iD_ServerLeader = termineIdServer.idS;  //il server "riconosce" il leader
		global.termineServer = termineIdServer.termine;  //il server aggiorna il suo termine con quello del leader
		global.stato = 1;	//il server diventa follower del leader
		daRispondere = 1
		
		//settaNuovoTimeout
	}]

	/*
	Tramite questa operazione il server riceve la richiesta di voto da un altro server candidato.
	Un server che riceve una comunicazione da un altro server con un termine corrente maggiore allora
	aggiorna il proprio termine corrente al nuovo valore.
	Se un server scopre di avere un termine corrente vecchio, diventa un follower.
	Se un server riceve una comunicazione con un termine corrente vecchio, rigetta la richiesta.
	*/
	[sendRequestVote( termineIdServer )( daRispondere ) {
		println@Console( "<<<< RV" )();
		 	settaNuovoTimeout;
			if(global.termineServer < termineIdServer.termine){
				daRispondere = 1; //se il server vota per il candidato risponde 1
				global.stato = 1;
				global.iD_ServerLeader = termineIdServer.idS
			}
			else{
				daRispondere = 0  //se il server non vota per il candidato risponde 0
			}

	}]

//*********************************************************************************************************************


//*************************************OPERAZIONE PER IL NETWORK VISUALIZER********************************************

/*
	Questa operazione invia al Network Visualizer una variabile composta da altre tre variabili 
	che mi rappresentano lo stato della lista dei carrelli disponibili, dei carrelli archiviati 
	e della lista delle merci.
	*/
	[riceviListe(request)(response){
		//println@Console("NETWORK: richiesta liste")();

		/*
		Se il server non è il leader allora non può eseguire le operazioni richiesta dal client,
		percui invierà a quest'ultimo un messaggio d'avviso e l'ID del server leader.
		*/
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		/*
		Se il server è il leader esegue l'operazione richiesta e ritorna un messaggio di avvenuta
		esecuzione più un intero = 100 per segnalare che l'operazione è stata eseguita.
		*/
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );
			acquire@SemaphoreUtils( global.semaforoMerci )( res );

			response.merciNet << global.listaMerci;
			response.carrelliNet << global.listaCarrelli;
			response.carrelliArchiviatiNet << global.listaCarrelliArchiviati;
			response.status = 100;
			response.message = "SERVER "+global.iD_Server+": Invio il mio stato.";
			release@SemaphoreUtils( global.semaforoMerci )( res );
			release@SemaphoreUtils( global.semaforoCarrelli )( res )
		}
	}]

//*********************************************************************************************************************

//*************************************OPERAZIONI PER L'ADMINISTRATOR**************************************************

	/*
	Questa operazione permette all'administrator di caricare inizialmente
	una serie di prodotti prestabiliti all'interno dello Shop.
	*/
	[caricaProdotti(request)(response){

		/*
		Se il server non è il leader allora non può eseguire le operazioni richiesta dal client,
		percui invierà a quest'ultimo un messaggio d'avviso e l'ID del server leader.
		*/
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		/*
		Se il server è il leader esegue l'operazione richiesta e ritorna un messaggio di avvenuta
		esecuzione più un intero = 100 per segnalare che l'operazione è stata eseguita.
		*/
		else{
			global.listaMerci << request;  // con = non funziona
			println@Console("\nHo ricevuto da Administrator:"+#global.listaMerci.oggetto+" prodotti")();
			for(x=0, x<#global.listaMerci.oggetto, x++){
				println@Console(global.listaMerci.oggetto[x].nome+"-"+global.listaMerci.oggetto[x].quantita)()
			};
			response.message = "SERVER "+global.iD_Server+": Lista Merci caricata con successo";
			global.administratorHaCaricato = true;
			//Sincronizziamo i server con i nuovi aggiornamenti
			response.status = 100;
			println@Console( "SYNC >>>>" )();
			sincronizzaServers

		}


	}]

	/*
	Questa operazione permette all'Administrator di aggiungere a suo piacimento
	una certa quantita di un determinato prodotto all'interno dello Shop.
	Se il prodotto da aggiungere nello Shop non era ancora presente, viene aggiunto alla lista delle merci.
	*/

	[aggiungiProdotto(request)(response){

		/*
		Se il server non è il leader allora non può eseguire le operazioni richiesta dal client,
		percui invierà a quest'ultimo un messaggio d'avviso e l'ID del server leader.
		*/
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		/*
		Se il server è il leader esegue l'operazione richiesta e ritorna un messaggio di avvenuta
		esecuzione più un intero = 100 per segnalare che l'operazione è stata eseguita.
		*/
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

			println@Console("\nHo ricevuto da Administrator una richiesta di aggiungere: ")();
			println@Console("Prodotto: "+request.nome)();
			println@Console("Quantita: "+request.quantita)();
			corrispondenzaTrovata = false;
			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			acquire@SemaphoreUtils( global.semaforoMerci )( res );

			//Cerchiamo il prodotto all'interno della lista delle merci
			for(i=0, i<#global.listaMerci.oggetto, i++){
				//Se il prodotto è già presente
				if(global.listaMerci.oggetto[i].nome == request.nome){
					corrispondenzaTrovata = true;
					println@Console("Trovata corrispondenza")();
					global.listaMerci.oggetto[i].quantita += request.quantita;
					println@Console("Quantita di "+request.nome+" aggiornata nello Shop: "+global.listaMerci.oggetto[i].quantita)();
					//Ristampo la lista delle merci nello Shop
					for(x=0, x<#global.listaMerci.oggetto, x++){
						println@Console(global.listaMerci.oggetto[x].nome+"-"+global.listaMerci.oggetto[x].quantita)()
					}
				}
			};
			//Se il prodotto non è presente nello Shop
			if( corrispondenzaTrovata == false ){
				global.listaMerci.oggetto[global.indiceProdotto] << request;
				global.indiceProdotto ++;

				for(x=0, x<#global.listaMerci.oggetto, x++){
					println@Console(global.listaMerci.oggetto[x].nome+"-"+global.listaMerci.oggetto[x].quantita)()
				}
			};
			release@SemaphoreUtils( global.semaforoMerci )( res );
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

			response.message = "SERVER "+global.iD_Server+": Quantita di prodotto aggiunta";

			response.status = 100;
			//sincronizzaServers;
			release@SemaphoreUtils( global.semaforoCarrelli )( res );

			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();

			sincronizzaServers
		}

	}]

	/*
	Questa operazione permette all'Administrator di eliminare
	una certa quantita di un determinato prodotto.
	Chiaramente la quantita che si vuole eliminare dovrà essere minore della
	quantità già presente nello Shop.
	*/

	[eliminaProdotto(request)(response){

		/*
		Se il server non è il leader allora non può eseguire le operazioni richiesta dal client,
		percui invierà a quest'ultimo un messaggio d'avviso e l'ID del server leader.
		*/
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}

		/*
		Se il server è il leader esegue l'operazione richiesta e ritorna un messaggio di avvenuta
		esecuzione più un intero = 100 per segnalare che l'operazione è stata eseguita.
		*/
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );
			acquire@SemaphoreUtils( global.semaforoMerci )( res );
			

			println@Console("\nHo ricevuto da Administrator una richiesta di eliminare: ")();
			println@Console("Prodotto: "+request.nome)();
			println@Console("Quantita: "+request.quantita)();

			corrispondenzaTrovata = false;
			//Cerchiamo il prodotto all'interno della lista delle merci
			for(i=0, i<#global.listaMerci.oggetto, i++){
				//Se il prodotto è già presente
				if(global.listaMerci.oggetto[i].nome == request.nome){
					corrispondenzaTrovata = true;
					println@Console("Trovata corrispondenza")();
					if( global.listaMerci.oggetto[i].quantita < request.quantita ) {
						println@Console("Non ci sono abbastanza quantita da eliminare!")();
						response.message = "SERVER "+global.iD_Server+": Non ci sono abbastanza quantita da eliminare!"
					}
					else{
						global.listaMerci.oggetto[i].quantita -= request.quantita;
						println@Console("Quantita di "+request.nome+" aggiornata nello Shop: "+global.listaMerci.oggetto[i].quantita)();
						//Ristampo la lista delle merci nello Shop
						for(x=0, x<#global.listaMerci.oggetto, x++){
							println@Console(global.listaMerci.oggetto[x].nome+"-"+global.listaMerci.oggetto[x].quantita)()
						};
						response.message = "SERVER "+global.iD_Server+": La quantita di prodotto è stata eliminata"
					}
				}
			};
			if( corrispondenzaTrovata == false ) {
			  println@Console("Non è stato trovato il prodotto di cui eliminare la quantita richiesta!")();
			  response.message = "SERVER "+global.iD_Server+": Non è stato trovato il prodotto di cui eliminare la quantita richiesta!"
			};
			
			response.status = 100; 
			//sincronizzaServers;
			

			release@SemaphoreUtils( global.semaforoMerci )( res );
			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
			sincronizzaServers
		}
	}]
//**********************************************************************************************************************************************


//**********************************************OPERAZIONI PER IL CLIENT************************************************************************


	/*
	Questa operazione permette al client di creare un nuovo carrello all'interno dello Shop.
	Se il nome utilizzato dal client fa riferimento ad un carrello che esiste già o che è stato acquistato,
	viene inviato al client un messaggio di avviso.
	*/
	[creaCarrello(request)(response){

		/*
		Se il server non è il leader allora non può eseguire le operazioni richiesta dal client,
		percui invierà a quest'ultimo un messaggio d'avviso e l'ID del server leader.
		*/
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

	  		println@Console("(1)Richiesta crea carrello '"+request.nome+"'")();
	  		esistente = 0;
	  		esistenteArchiviato = 0;
	  		for(i=0, i<#global.listaCarrelliArchiviati.carrello, i++){
	   			if(global.listaCarrelliArchiviati.carrello[i].nome == request.nome){
	   				response.message ="SERVER "+global.iD_Server+": Il nome del carrello e'riservato. Si prega di utilizzare un nome diverso.";
	   				esistenteArchiviato = 1
	   			}
			};
			if( esistenteArchiviato == 0 ) {
	  			for(i=0, i<#global.listaCarrelli.carrello, i++){
	   				if(global.listaCarrelli.carrello[i].nome == request.nome){
	   					response.message ="SERVER "+global.iD_Server+": Carrello gia' esistente! Si prega di utilizzare un nome diverso.";
	   					esistente = 1
	   				}
				};
				if( esistente == 0 ) {
					global.listaCarrelli.carrello[global.indiceCarrello] << request;
	  				global.indiceCarrello++;
					response.message ="SERVER "+global.iD_Server+": Carrello "+request.nome+" creato con successo."
				}
			};
			
			response.status = 100; 
			//sincronizzaServers;

			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
			sincronizzaServers
		}
	}]


	/*
	Questa operazione invia al client la lista dei prodotti acquistabili nello Shop.
	Se la lista non è ancora stata caricata dall'Administrator nello Shop,
	il server invia un messaggio di avviso al client.
	*/
	[vediListaOggetti(request)(response){
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			println@Console("(2)Vedi lista merci")();
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );
			acquire@SemaphoreUtils( global.semaforoMerci )( res );

			if( global.administratorHaCaricato == true ) {
				response.listaShop << global.listaMerci;
				response.message = "SERVER: Ecco la lista dei prodotti disponibili:"
			}
			else{
				//response.listaShop << global.listaMerci;
				response.message = "SERVER: La lista dei prodotti disponibili non e' ancora stata caricata."
			};
			response.status = 100;
			release@SemaphoreUtils( global.semaforoMerci )( res );
			release@SemaphoreUtils( global.semaforoCarrelli )( res )
		}
	}]

	/*
	Questa operazione permette al client di eliminare un carrello dalla lista dei carrelli
	presenti all'interno dello Shop. Se non è presente il carrello corrispondente al nome
	digitato dal client, allora il server risponde al client un messaggio d'avviso.
	Se il nome del carrello corrisponde, allora ritornano disponibili i prodotti contenuti in esso nello Shop.
	*/
  	[cancellaCarrello(request)(response){
  		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

		  	println@Console("(3)Cancella carrello '"+request.nome+"'")();
		  	cancellato = 0;
		  	for(i=0, i<#global.listaCarrelli.carrello, i++){
		  		if(global.listaCarrelli.carrello[i].nome == request.nome){
		  			for(j=0, j<#global.listaCarrelli.carrello[i].lista.oggetto, j++){
		  				for(k=0, k<#global.listaMerci.oggetto, k++){
		  					if(global.listaCarrelli.carrello[i].lista.oggetto[j].nome == global.listaMerci.oggetto[k].nome){
		  						release@SemaphoreUtils( global.semaforoCarrelli )( res );
		  						acquire@SemaphoreUtils( global.semaforoMerci )( res );
		  						global.listaMerci.oggetto[k].quantita += int(global.listaCarrelli.carrello[i].lista.oggetto[j].quantita);
		  						release@SemaphoreUtils( global.semaforoMerci )( res );
		  						acquire@SemaphoreUtils( global.semaforoCarrelli )( res )
		  					}	
		  				}
		  			};
		   			undef(global.listaCarrelli.carrello[i]);
					global.indiceCarrello--;
					response.message ="SERVER "+global.iD_Server+": Carrello cancellato con successo. I prodotti sono tornati disponibili nello Shop.";
		   			cancellato = 1
		   		}
			};
			if(cancellato == 0){
				response.message = "SERVER "+global.iD_Server+": Carrello inesistente! Si prega di provare con un altro nome."
			};
			
			response.status = 100; 
			//sincronizzaServers;

			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
			sincronizzaServers
		}
	}]


	/*
  	Questa operazione permette ad un cliente di acquistare un carrello.
  	Se acquistato, il carrello va in archivio e il relativo nome non può più essere utilizzato.
  	*/
  	[acquistaCarrello(request)(response){
  		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

	  		println@Console("(4)Acquista carrello '"+request.nome+"'")();
	  		acquistato = 0;
	  		for(i=0, i<#global.listaCarrelli.carrello, i++){
	  			if(global.listaCarrelli.carrello[i].nome == request.nome){
	  				acquistato = 1;
	  				//Inserisco il carrello all'interno della lista dei carrelli archiviati
	  				global.listaCarrelliArchiviati.carrello[global.indiceCarrelloArchiviato] << global.listaCarrelli.carrello[i];
	  				global.indiceCarrelloArchiviato++;
					response.message ="SERVER "+global.iD_Server+": Carrello "+request.nome+" acquistato con successo.";
					//Tolgo il carrello dalla lista dei carrelli ancora disponibili
	   				undef(global.listaCarrelli.carrello[i]);
					global.indiceCarrello--
	   			}
			};
			if( acquistato == 0 ) {
		    	response.message = "SERVER "+global.iD_Server+": ERRORE! Per poter acquistare un carrello bisogna prima crearne uno."
			};
			
			response.status = 100; 
			//sincronizzaServers;

			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
			sincronizzaServers
		}
 	}]


 	/*
	Questa operazione permette al client di aggiungere un prodotto con la sua relativa quantità
	all'interno di un carrello precedentemente creato all'interno dello Shop.
	Per prima cosa si verifica che l'Administrator abbia caricato i prodotti all'interno dello Shop.
	Se ciò non è avvenuto, si invia un messaggio d'avviso al client.
	Come secondo passo, vengono effettuati controlli sulla disponibilità dei prodotti e quantità
	all'interno dello Shop, dopodichè si passa al controllo sul nome del carrello.
	Infine si arriva all'aggiunta vera e propria delle merci nel carrello.
	*/
  	[aggiungiElementi(request)(response){
  		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

	  		println@Console("(5)Aggiungi prodotti '"+request.nomeProdotto+"'")();
		  	if(global.administratorHaCaricato == true){
		  		disponibile = false; // Mi dice se il prodotto e la sua quantita sono disponibili nello shop
		  		//Ciclo sulla lista delle merci presente nello shop per vedere se è possibili effettuare l'aggiunta

		  		release@SemaphoreUtils( global.semaforoCarrelli )( res );
		  		acquire@SemaphoreUtils( global.semaforoMerci )( res );

		  		for ( k=0, k<#global.listaMerci.oggetto, k++ ) {
		  	    	if(global.listaMerci.oggetto[k].nome == request.nomeProdotto && global.listaMerci.oggetto[k].quantita >= request.numeroQuantita){
		  	    		disponibile = true //guardo se la quantita è disponibile nello shop
		  	    		//global.listaMerci.oggetto[k].quantita -= int(request.numeroQuantita)
		  	    	}
		  		};

		  		if(disponibile == true){
		  			//Ciclo sui nomi di ogni carrello contenuto nella lista listaCarrelli
		  			for(i=0, i<#global.listaCarrelli.carrello, i++){
		  				//Controllo se il nome del carrello corrisponde con quello della listaCarrelli
		  				//println@Console("sto ciclando i carrelli disponibili")();
		  				if(global.listaCarrelli.carrello[i].nome == request.nomeCarrello){
		  					println@Console("Ho trovato il carrello corrispondente in posizione "+i)();
		  					//se il carrello non ha nessun prodotto, aggiungo
		  					if(#global.listaCarrelli.carrello[i].lista.oggetto == 0){
		  						//aggiungi in prima posizione i prodotti
		  						//ultimaPos = #global.listaCarrelli.carrello[i].lista.oggetto;
		  						println@Console("Il carrello non aveva ancora nessun prodotto")();
		  						global.listaCarrelli.carrello[i].lista.oggetto[0].nome = request.nomeProdotto;
		  						global.listaCarrelli.carrello[i].lista.oggetto[0].quantita = int(request.numeroQuantita);
		  						//Tolgo la quantita richiesta dallo Shop
		  						for ( k=0, k<#global.listaMerci.oggetto, k++ ) {
		  	    					if(global.listaMerci.oggetto[k].nome == request.nomeProdotto){
		  	    						global.listaMerci.oggetto[k].quantita -= int(request.numeroQuantita)
		  	    					}
		  						};
		  						prodottiCaricati=true
		  					}
		  					//se invece ci sono già dei prodotti nel carrello eseguo i controlli
		  					else{
		  						//ciclo i prodotti presenti nel carrello
			  					for(j=0, j<#global.listaCarrelli.carrello[i].lista.oggetto, j++){
			  						//controllo se il prodotto da aggiungere era già presente nel carrello
			  						println@Console("Controllo se il prodotto e' già presente nel carrello")();
			  						if (global.listaCarrelli.carrello[i].lista.oggetto[j].nome == request.nomeProdotto){
			  							println@Console("Il prodotto e' presente nel carrello")();
			  							//aggiungo solo la quantità e guardo la disponibilità nello shop (listaMerci)
			  							println@Console("Aggiorno la quantita'"+global.listaCarrelli.carrello[i].lista.oggetto[j].quantita)();
			  							global.listaCarrelli.carrello[i].lista.oggetto[j].quantita += int(request.numeroQuantita);
			  							for ( k=0, k<#global.listaMerci.oggetto, k++ ) {
			  	    						if(global.listaMerci.oggetto[k].nome == request.nomeProdotto){
			  	    							global.listaMerci.oggetto[k].quantita -= int(request.numeroQuantita)
			  	    						}
			  							};
			  							prodottiCaricati = true
			  						}
			  					};
								if(prodottiCaricati == false){
		  							// se il prodotto non era ancora stato aggiunto prima nel carrello, lo aggiungo in fondo
		  							println@Console("Il prodotto non e' presente nel carrello")();
		  							ultimaPos = #global.listaCarrelli.carrello[i].lista.oggetto;
		  							global.listaCarrelli.carrello[i].lista.oggetto[ultimaPos].nome = request.nomeProdotto;
		  							global.listaCarrelli.carrello[i].lista.oggetto[ultimaPos].quantita = int(request.numeroQuantita);
		  							for ( k=0, k<#global.listaMerci.oggetto, k++ ) {
		  	    						if(global.listaMerci.oggetto[k].nome == request.nomeProdotto){
		  	    							global.listaMerci.oggetto[k].quantita -= int(request.numeroQuantita)
		  	    						}
		  							};
		  							prodottiCaricati=true
		  						}
		  					}
		  				}
		  			};
		  			if (prodottiCaricati){response.message="SERVER "+global.iD_Server+": Prodotti caricati con successo."}
		  			else {response.message="SERVER "+global.iD_Server+": Errore caricamento prodotti! Controllare il nome del carrello/prodotto/quantita."}
		  		}
		  		else{
		  			response.message = "SERVER "+global.iD_Server+": Il prodotto o la quantita inserita non e' disponibile."
		  		};
		  		release@SemaphoreUtils( global.semaforoMerci )( res );
		  		acquire@SemaphoreUtils( global.semaforoCarrelli )( res )
		  	}
		  	else{
		  		response.message = "SERVER "+global.iD_Server+": L'Administrator non ha ancora caricato i prodotti nello Shop."
		  	};
		  	
		  	response.status = 100; 
		  	//sincronizzaServers;

		  	release@SemaphoreUtils( global.semaforoCarrelli )( res );
		  	//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
		  	sincronizzaServers
		}
	}]


	/*
	Questa operazione permette al client di rimuovere un prodotto con la sua relativa quantità
	all'interno di un carrello precedentemente creato all'interno dello Shop.
	Per prima cosa si verifica che l'Administrator abbia caricato i prodotti all'interno dello Shop.
	Se ciò non è avvenuto, si invia un messaggio d'avviso al client.
	Come secondo passo, vengono effettuati controlli sul nome del carrello, sulla disponibilità
	dei prodotti e quantità all'interno del carrello.
	Infine, se tutti i controlli hanno dato esito positivo, si passa alla vera e propria
	eliminazione delle merci dal carrello.
	  */
	[rimuoviElementi(request)(response){
		if(global.stato != 3){
			response.status = global.iD_ServerLeader;
			response.message = "SERVER "+global.iD_Server+": Non sono io il leader."
		}
		else{
			acquire@SemaphoreUtils( global.semaforoCarrelli )( res );

			println@Console("(6)Rimuovi elementi '"+request.nomeProdotto+"'")();
	  		//Ciclo sui nomi di ogni carrellocontenuto nella lista listaCarrelli
	  		if(global.administratorHaCaricato == true){
	  			carrelloTrovato = false;
	  			prodottoTrovato = false;
	  			quantitaTrovata = false;
	  			acquire@SemaphoreUtils( global.semaforoMerci )( res );
				for (i=0, i<#global.listaCarrelli.carrello, i++){
					//Controllo se il nome del carrello corrisponde con quello della listaCarrelli
					if (global.listaCarrelli.carrello[i].nome == request.nomeCarrello){
						carrelloTrovato = true;	//ho trovato il carrello
						//Ciclo sui nomi degli elementi in ogni carrello
						for (j=0, j<#global.listaCarrelli.carrello[i].lista.oggetto, j++){
							//Controllo se il nome dell'elemento da rimuovere è già presente nel carrello
							if (global.listaCarrelli.carrello[i].lista.oggetto[j].nome == request.nomeProdotto){
								prodottoTrovato = true; //ho trovato il prodotto
								//Guardo la quantità dell'elemento presente nel carrello
								if (global.listaCarrelli.carrello[i].lista.oggetto[j].quantita >= request.numeroQuantita){
									quantitaTrovata = true; //la quantita nel carrello è sufficientemente grande da essere ridotta della quantità richiesta
									global.listaCarrelli.carrello[i].lista.oggetto[j].quantita -= int(request.numeroQuantita);
									//Rendo disponibile nello Shop la quantità di prodotto tolta dal carrello
									for ( z=0, z<#global.listaMerci.oggetto, z++ ) {
	  		    						if(global.listaMerci.oggetto[z].nome == request.nomeProdotto){
	  		    							global.listaMerci.oggetto[z].quantita += int(request.numeroQuantita)
	  		    						}
	  								}
								}
							}
						}
					}
				};
				if(carrelloTrovato == false || prodottoTrovato == false || quantitaTrovata == false){
					response.message = "SERVER "+global.iD_Server+": ERRORE! Controllare il nome del carrello/prodotto e la quantita inserita."
				}
				else{
					response.message = "SERVER "+global.iD_Server+": "+request.numeroQuantita+" x "+request.nomeProdotto+" rimosso dal carrello."
				};
				release@SemaphoreUtils( global.semaforoMerci )( res )
			}
			else{
				response.message = "SERVER "+global.iD_Server+": Spiacenti, l'administrator non ha ancora caricato la lista dei prodotti nello Shop."
			};
			
			response.status = 100; 
			//sincronizzaServers

			release@SemaphoreUtils( global.semaforoCarrelli )( res );
			//Sincronizziamo i server con i nuovi aggiornamenti
			println@Console( "SYNC >>>>" )();
			sincronizzaServers
		}
	}]
}