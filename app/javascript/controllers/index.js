import { application } from "controllers/application"

import A2uiDataController from "controllers/a2ui_data_controller"
import A2uiBindingController from "controllers/a2ui_binding_controller"
import A2uiActionController from "controllers/a2ui_action_controller"
import BriefingController from "controllers/briefing_controller"

application.register("a2ui-data", A2uiDataController)
application.register("a2ui-binding", A2uiBindingController)
application.register("a2ui-action", A2uiActionController)
application.register("briefing", BriefingController)
