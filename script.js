document.querySelector(".hamburger").addEventListener("click", function(){ //irá ficar escutando o evento click
   document.querySelector(".container").classList.toggle("show-menu"); //a partir da lista de classes, irá adicionar ou remover uma classe. Se tiver a classe show-menu, irá remover, se não tiver, irá adicionar.
});
