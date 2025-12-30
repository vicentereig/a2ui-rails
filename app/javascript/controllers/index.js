import { application } from "./application"

import A2uiDataController from "./a2ui_data_controller"
import A2uiBindingController from "./a2ui_binding_controller"
import A2uiActionController from "./a2ui_action_controller"

application.register("a2ui-data", A2uiDataController)
application.register("a2ui-binding", A2uiBindingController)
application.register("a2ui-action", A2uiActionController)
