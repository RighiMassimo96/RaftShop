/*
Variabile che viene scambiata tra i vari server 
nell'algoritmo Raft
*/
type TermineIdServer: void{
	.termine?: int
	.idS: int
}
/*
Macro-variabile che viene inviata dal server leader
a tutti gli altri server per aggiornare le loro variabili
globali.
*/
type syncro: void{
	.merci[0,*]: typelistaOggetti
	.carrelli[0,*]: typelistaCarrelli
	.carrelliArchiviati[0,*]: typelistaCarrelli
	.indiceM: int
	.indiceC: int
	.indiceCA: int
	.merceCaricata: bool
	.id: int
}
/*
Lista dei carrelli disponibili nel sistema.
*/
type typelistaCarrelli: void{
	.carrello*: typeCarrello
}
/*
Variabile che mi rappresenta gli attributi di 
un carrello.
*/
type typeCarrello: void{
	.nome: string
	.lista?: typelistaOggetti
}
/*
Variabile utilizzata sia per definire la lista delle merci presente
nel Raft Shop, che per definire la lista di prodotti che
un client aggiunge all'interno di uno stesso carrello.
*/
type typelistaOggetti: void{
	.oggetto*: typeOggetto
}
/*
Variabile che mi rappresenta gli attributi di un oggetto/prodotto.
*/
type typeOggetto: void{
	.nome: string
	.quantita: int
}


interface RaftInterface{
  	RequestResponse:
    	sendRequestVote( TermineIdServer )( int ) throws serverOffline( void ),
  		sendHeartBeat( TermineIdServer )( int ) throws serverOffline( void ),
		sincronizzaServers ( syncro )( int ) throws serverOffline( void )
  	OneWay:
  		startServer( void )
}
