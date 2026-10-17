const express = require('express');
const controller = require('../controllers/hospital.controller');
const { authenticate, allowRoles } = require('../middleware/auth.middleware');

const router = express.Router();

router.get('/departments', controller.listDepartments);
router.post('/departments', authenticate, allowRoles('admin'), controller.createDepartment);
router.get('/doctors', controller.listDoctors);
router.get('/doctors/:id', controller.getDoctor);
router.post('/doctors', authenticate, allowRoles('admin'), controller.createDoctor);
router.patch('/doctors/:id', authenticate, allowRoles('admin'), controller.updateDoctor);

module.exports = router;
