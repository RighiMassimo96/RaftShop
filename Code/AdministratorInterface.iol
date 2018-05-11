/*
Lista delle merci inzialmente caricate all'interno dello Shop.
*/
type typelistaProdotti: void{
  .oggetto*: typeProdotto
}
/*
Vriabile che mi spiega com'è fatto un prodotto.
*/
type typeProdotto: void{
  .nome: string
  .quantita: int
}
/*
Risposta.
*/
type typeReplay: void{
  .message: string
  .status?: int
}

interface AdministratorInterface{
  RequestResponse:
    caricaProdotti(typelistaProdotti)(typeReplay),
    aggiungiProdotto(typeProdotto)(typeReplay),
    eliminaProdotto(typeProdotto)(typeReplay)
}
