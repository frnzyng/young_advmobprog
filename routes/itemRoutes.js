const express = require("express");
const { getItems, getActiveItems, getArchivedItems, createItem, updateItem, deleteItem } = require("../controllers/itemController");

const router = express.Router();

router.route("/").get(getItems).post(createItem);
router.route("/active").get(getActiveItems);
router.route("/archived").get(getArchivedItems);
router.route("/:id").put(updateItem).delete(deleteItem);

module.exports = router;