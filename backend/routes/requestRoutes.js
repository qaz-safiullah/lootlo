const express = require('express');
const router = express.Router();
const { 
    requestItem, 
    proposeTime, 
    acceptProposal, 
    confirmHandshake, 
    getReceivedRequests, 
    getMyRequests, 
    cancelRequest ,
    checkRequestStatus
} = require('../controllers/requestController');
const { protect } = require('../middlewares/authMiddleware');

// All request routes must be protected via JWT middleware
router.use(protect);

// 1. Creating a request (Taker actions)
router.post('/:itemId', requestItem);
router.get('/my-requests', getMyRequests);
router.put('/:requestId/cancel', cancelRequest);

// 2. Proposing and Accepting Timelines (The Negotiation Core)
router.put('/:requestId/propose', proposeTime);
router.put('/:requestId/accept-proposal', acceptProposal);

// 3. Handover Handshake (Dual Confirmation Execution)
router.put('/:requestId/confirm', confirmHandshake);

// 4. Giver viewing incoming items to review dashboard inventory
router.get('/received', getReceivedRequests);

router.get('/:itemId/check', checkRequestStatus);

module.exports = router;