const  navToggle = document.querySelector(".nav-toggle");
const  links = document.querySelector(".links");

navToggle.addEventListener("click", function() {
  console.log("hello")
  links.classList.toggle("show-links")
});
