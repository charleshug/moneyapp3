// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import SidebarController from "./sidebar_controller"
eagerLoadControllersFrom("controllers", application)
application.register("sidebar", SidebarController)
