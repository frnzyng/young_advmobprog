const express = require('express');
const { getUsers, getUserInfo, createUser, updateUser, deleteUser, loginUser, registerUser } = require('../controllers/userController');

const router = express.Router();

router.route('/').get(getUsers).post(createUser);
router.route('/info/:id').get(getUserInfo)
router.route('/:id').put(updateUser).delete(deleteUser);
router.post('/login', loginUser);
router.post('/register', registerUser);

module.exports = router;